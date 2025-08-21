const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const indexRouter = require('./routes/index');
const chatRoutes = require('./routes/chatRoutes');

app.use(express.json({limit : '50mb'}));
app.use(express.urlencoded({ extended: false, limit: '50mb' }));

app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

app.use('/api', indexRouter);
app.use('/api/chat', chatRoutes);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});