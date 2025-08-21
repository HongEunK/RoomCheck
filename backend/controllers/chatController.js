const axios = require('axios');

// 사용자의 채팅 메시지를 받아 AI 모델의 응답을 반환하는 컨트롤러
exports.getAiChatResponse = async (req, res) => {
    // 사용자 요청 본문(body)에서 데이터 추출
    const { userMessage, conversationHistory } = req.body;

    // 입력값 유효성 검사
    if (!userMessage || userMessage.trim() === '') {
        return res.status(400).json({ 
            success: false, 
            message: 'userMessage는 필수 항목입니다.' 
        });
    }

    try {
        // Ollama API URL을 환경 변수에서 가져오기
        const ollamaApiUrl = process.env.OLLAMA_API_URL;
        if (!ollamaApiUrl) {
            // 환경 변수가 설정되지 않은 경우 에러를 발생시켜 문제를 빠르게 인지하도록 함
            throw new Error('OLLAMA_API_URL이 환경 변수에 설정되지 않았습니다.');
        }

         // 더 강력하고 명확해진 시스템 프롬프트
        const systemPrompt = `당신은 실내 정리 및 청소 전문가입니다. 항상, 어떤 경우에도, 예외 없이 한국어로만 답변해야 합니다. 영어, 한자 또는 다른 언어를 절대 사용하지 마세요. 사용자의 방 상태를 분석하고 실용적인 정리 방법을 제안합니다.`;

        // Llama 3 공식 프롬프트 템플릿 적용
        const formattedPrompt = `<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n${systemPrompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n${userMessage}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n`;

        const ollamaResponse = await axios.post(`${ollamaApiUrl}/api/generate`, {
            model: "llama3",
            prompt: formattedPrompt, // 수정된 프롬프트 사용
            stream: false,
            options: {
                temperature: 0.3,
                // 응답의 끝을 명확히 하기 위한 stop 토큰 설정
                stop: ["<|eot_id|>", "<|end_of_text|>"]
            }
        });

        let aiMessage = ollamaResponse.data.response;

        res.status(200).json({
            success: true,
            message: aiMessage.trim()
        });

    } catch (error) {
        console.error('Ollama API 호출 중 오류 발생:', error.message);
        res.status(500).json({ 
            success: false, 
            message: 'AI 어시스턴트를 호출하는 데 실패했습니다.' 
        });
    }
};