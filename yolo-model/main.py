from fastapi import FastAPI, UploadFile, File
from ultralytics import YOLO
from torch.serialization import add_safe_globals
from torch.nn.modules.conv import Conv2d
from torch.nn.modules.container import Sequential, ModuleList
from torch.nn.modules.batchnorm import BatchNorm2d
from torch.nn.modules.activation import SiLU
from ultralytics.nn.tasks import DetectionModel
import ultralytics.nn.modules.conv as ultralytics_conv
import ultralytics.nn.modules.block as ultralytics_block
import ultralytics.nn.modules.head as ultralytics_head
from torch.nn.modules.pooling import MaxPool2d
from torch.nn.modules.upsampling import Upsample
import numpy as np
import cv2
import logging
from pydantic import BaseModel
import base64
import io
from PIL import Image
import yaml

add_safe_globals([
    Conv2d,
    DetectionModel,
    Sequential,
    ModuleList,
    ultralytics_conv.Conv,
    ultralytics_conv.Concat,
    BatchNorm2d,
    SiLU,
    ultralytics_block.C2f,
    ultralytics_block.Bottleneck,
    ultralytics_block.SPPF,
    ultralytics_head.Detect,
    ultralytics_block.DFL,
    MaxPool2d,
    Upsample,
])

app = FastAPI()

class ImageData(BaseModel):
    image: str

# 두 모델 로드
model1 = YOLO("best1.pt")
model2 = YOLO("best2.pt")

# 각 모델 클래스 이름 읽어오기
with open("data1.yaml", "r", encoding="utf-8") as f:
    class_names1 = yaml.safe_load(f)["names"]

with open("data2.yaml", "r", encoding="utf-8") as f:
    class_names2 = yaml.safe_load(f)["names"]

# 통합 클래스 목록 생성
unified_class_names = list(set(class_names1 + class_names2))

# 각 모델의 클래스 인덱스를 통합 클래스 인덱스로 매핑
map_1_to_unified = {cls_idx: unified_class_names.index(name) for cls_idx, name in enumerate(class_names1)}
map_2_to_unified = {cls_idx: unified_class_names.index(name) for cls_idx, name in enumerate(class_names2)}


def run_model(model, class_map, image_np):
    detections = []
    results = model.predict(source=image_np, conf=0.25, verbose=False)
    for result in results:
        boxes = result.boxes.xyxy.cpu().numpy()
        classes = result.boxes.cls.cpu().numpy()
        confidences = result.boxes.conf.cpu().numpy()
        for box, cls, conf in zip(boxes, classes, confidences):
            # 매핑된 인덱스를 사용해 통합 클래스 목록에서 이름 가져오기
            unified_cls_idx = class_map[int(cls)]
            detections.append({
                "box": [round(coord, 2) for coord in box.tolist()],
                "class": unified_cls_idx,
                "label": unified_class_names[unified_cls_idx],
                "confidence": round(float(conf), 2)
            })
    return detections

@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image_np = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image_np is None:
        return {"error": "Invalid image"}

    # 각 모델을 실행하고 결과를 통합 클래스 목록에 맞게 반환
    detections1 = run_model(model1, map_1_to_unified, image_np)
    detections2 = run_model(model2, map_2_to_unified, image_np)
    

    # 두 결과를 합침
    detections = detections1 + detections2
    detections = remove_duplicates(detections, iou_threshold=0.5)

    return {"detections": detections}

@app.post("/upload")
async def upload_image(data: ImageData):
    image_bytes = base64.b64decode(data.image)
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image_np = np.array(image)

    # 각 모델을 실행하고 결과를 통합 클래스 목록에 맞게 반환
    detections1 = run_model(model1, map_1_to_unified, image_np)
    detections2 = run_model(model2, map_2_to_unified, image_np)

    # 두 결과를 합침
    detections = detections1 + detections2
    detections = remove_duplicates(detections, iou_threshold=0.5)

    return {"message": "객체 탐지 완료", "detections": detections}

def remove_duplicates(detections, iou_threshold=0.5):
    filtered = []
    detections.sort(key=lambda x: x['confidence'], reverse=True)  # confidence 높은 순 정렬

    while detections:
        current = detections.pop(0)
        filtered.append(current)
        detections = [
            d for d in detections
            if d['label'] != current['label'] or iou(d['box'], current['box']) < iou_threshold
        ]
    return filtered

def iou(box1, box2):
    # box = [x1, y1, x2, y2]
    x1 = max(box1[0], box2[0])
    y1 = max(box1[1], box2[1])
    x2 = min(box1[2], box2[2])
    y2 = min(box1[3], box2[3])
    inter_area = max(0, x2 - x1) * max(0, y2 - y1)

    box1_area = (box1[2] - box1[0]) * (box1[3] - box1[1])
    box2_area = (box2[2] - box2[0]) * (box2[3] - box2[1])
    union_area = box1_area + box2_area - inter_area

    return inter_area / union_area if union_area > 0 else 0
