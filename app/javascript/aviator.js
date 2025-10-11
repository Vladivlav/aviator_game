const canvas = document.getElementById('gameCanvas');
// Проверяем, существует ли canvas перед использованием
const ctx = canvas.getContext('2d');

// Установка размера canvas (лучше делать это через CSS для адаптивности)
// Сейчас оставим, как есть, но в будущем лучше использовать canvas.clientWidth/clientHeight
canvas.width = 800;
canvas.height = 600;

let animationId;
// NOTE: multiplier должен приходить от сервера
let multiplier = 1.00;
let isFlying = false;
let gameEnded = false;

// Начальные координаты
const START_X = 100;
const START_Y = canvas.height - 100;

class Rocket { // Переименовали в Rocket для лучшего соответствия графике
    constructor() {
        this.x = START_X;
        this.y = START_Y;
        this.size = 20;
        this.angle = 0;
        this.speed = 0.5; // Базовая скорость
    }

    draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.angle);
        
        // --- Отрисовка РАКЕТЫ ---
        
        // 1. Хвост (Пламя)
        ctx.fillStyle = multiplier > 2 ? '#ff6600' : '#ffcc00';
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(-20, 5);
        ctx.lineTo(-40, 0);
        ctx.lineTo(-20, -5);
        ctx.closePath();
        ctx.fill();
        
        // 2. Тело ракеты
        ctx.fillStyle = '#00CED1'; // Яркий бирюзовый
        ctx.fillRect(0, -5, 30, 10);
        
        // 3. Нос ракеты
        ctx.fillStyle = '#FF4500'; // Красный
        ctx.beginPath();
        ctx.moveTo(30, -5);
        ctx.lineTo(35, 0);
        ctx.lineTo(30, 5);
        ctx.closePath();
        ctx.fill();
        
        // 4. Иллюминатор
        ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
        ctx.beginPath();
        ctx.arc(15, 0, 3, 0, Math.PI * 2, true);
        ctx.fill();
        
        ctx.restore();
    }

    update() {
        if (isFlying && !gameEnded) {
            // Плавное нарастание скорости, имитирующее параболу
            this.speed += 0.005; // Ускорение
            
            // Движение: скорость по X и Y увеличивается с ростом speed
            this.x += this.speed * 1.5;
            this.y -= this.speed * 0.8;
            
            // Угол (направление)
            this.angle = -Math.PI / 6; // Наклоняем ракету вверх-вправо
        }
    }
}

const airplane = new Rocket(); // Используем новый класс Rocket

function drawCurve() {
    ctx.beginPath();
    ctx.strokeStyle = '#00CED1'; // Голубая линия
    ctx.lineWidth = 3;
    
    // Начало в стартовой точке ракеты
    ctx.moveTo(START_X, START_Y);
    
    // Рисуем линию к текущей позиции ракеты
    ctx.lineTo(airplane.x, airplane.y);
    
    ctx.stroke();
}

function drawFrame() {
    // 1. Очистка всего холста (КЛЮЧЕВОЙ ШАГ!)
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // 2. Фон (Отрисовываем фон после очистки)
    ctx.fillStyle = '#0d1117';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // 3. Рисуем линию пути и саму ракету
    drawCurve();
    airplane.draw();
}

function animate() {
    airplane.update();
    
    // 2. 🚨 Отрисовываем кадр: 
    // drawFrame() отвечает за очистку холста, фон и отрисовку ракеты.
    drawFrame();

    // 3. Продолжаем цикл, если игра не окончена
    if (!gameEnded) {
        animationId = requestAnimationFrame(animate);
    }
}

// =======================================================
// ЭКСПОРТИРУЕМ ФУНКЦИИ для использования в скрипте канала
// =======================================================

// ЭКСПОРТ: Запускает анимацию и игру. Вызывается по команде СЕРВЕРА.
function startGame() {
    // 1. Установка активного состояния
    isFlying = true;
    gameEnded = false;
    
    // 2. Управление состоянием UI
    const placeBetBtn = document.getElementById('placeBet');
    const cashoutBtn = document.getElementById('cashout');
    
    if (placeBetBtn) placeBetBtn.disabled = true; // Ставки закрыты
    if (cashoutBtn) cashoutBtn.disabled = false; // Кэшаут доступен
    
    // 3. Запуск анимационного цикла
    animate();
    
    console.log("Игра начата по команде сервера.");
}

function resetGame() {
    // 1. Сброс переменных состояния
    isFlying = false; // Анимация остановлена
    gameEnded = true;  // Показываем, что раунд завершен, можно ставить
    multiplier = 1.00;
    
    // 2. Сброс позиций графических элементов
    airplane.x = START_X;
    airplane.y = START_Y;
    airplane.speed = 0.5; // Сброс скорости
    
    // 3. 🚀 ПРИНУДИТЕЛЬНАЯ ОТРЕСОВКА: 
    // Гарантируем, что ракета появилась в START_X/Y на чистом фоне.
    drawFrame(); 
    
    console.log("Игра сброшена в начальное состояние, ожидание ставок.");
}

// ЭКСПОРТ: Останавливает игру (падение или кэшаут). Вызывается по команде СЕРВЕРА.
function endGame(reason = 'GAME OVER') {
    airplane.speed = 0;
    isFlying = false;
    gameEnded = true;
    
    const placeBetBtn = document.getElementById('placeBet');
    const cashoutBtn = document.getElementById('cashout');
    
    // Управление состоянием UI
    if (placeBetBtn) placeBetBtn.disabled = false;
    if (cashoutBtn) cashoutBtn.disabled = true;
    
    cancelAnimationFrame(animationId); // Важно остановить цикл анимации!

    console.log(`${reason} at`, multiplier.toFixed(2) + 'x');
}

// Глобальный элемент, чтобы не искать его каждый раз
const bettingTimerContainer = document.getElementById('betting-timer-container');
const bettingProgressBar = document.getElementById('betting-progress');

function startBettingTimerCSS() {
    // 1. Показываем контейнер
    bettingTimerContainer.style.display = 'block';
    
    // 2. Сбрасываем и запускаем анимацию
    
    // Сброс: Это обнулит полосу, если она не успела закончиться в прошлый раз
    bettingProgressBar.style.animation = 'none';
    bettingProgressBar.offsetHeight; // Хитрость для принудительного рефлоу (сброса анимации)

    // Запуск: Применяем анимацию
    bettingProgressBar.style.animation = 'fillTimer 5s linear forwards';
    
    console.log("CSS-таймер запущен на 5 секунд.");
}

function hideBettingTimer() {
    // Скрываем таймер, когда начинается полет или происходит краш
    bettingTimerContainer.style.display = 'none';
    bettingProgressBar.style.animation = 'none';
}

// =======================================================
// ИНИЦИАЛИЗАЦИЯ (ОСТАВЛЯЕМ ТОЛЬКО UI-ЛОГИКУ)
// =======================================================
document.addEventListener('DOMContentLoaded', () => {
    const cashoutButton = document.getElementById('cashout');
    const placeBetButton = document.getElementById('placeBet');
    
    if (placeBetButton && cashoutButton) {
        // Устанавливаем начальное состояние
        cashoutButton.disabled = true;
        placeBetButton.disabled = false; 
        
        // Инициализация Canvas после загрузки DOM
        ctx.fillStyle = '#0d1117';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
    } else {
        console.error("Aviator JS: Не найдены кнопки placeBet или cashout. Проверьте ваш HTML.");
    }
});

export { startGame, endGame, resetGame, startBettingTimerCSS, hideBettingTimer };


// Определяем базовый URL для API
const API_URL = '/api/login';
// Ключи для хранения в браузере
const AUTH_KEY = 'auth_token';
const SESSION_KEY = 'session_token';

/**
 * Инициализирует сессию пользователя: создает нового гостя или восстанавливает старого.
 */
async function initializeSession() {
    // 1. Проверяем, есть ли токены в LocalStorage
    const authToken = localStorage.getItem(AUTH_KEY);
    const sessionToken = localStorage.getItem(SESSION_KEY);
    
    // Отправляем на сервер наиболее надежный токен (auth_token) или session_token, если auth_token утерян
    const tokenToSend = authToken || sessionToken || '';
    
    // Подготовка тела запроса
    const requestBody = { 
        auth_token: authToken, 
        session_token: sessionToken 
    };

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });

        // Проверка HTTP-статуса
        if (!response.ok) {
            // Если сервер вернул 401 (Unauthorized) или 500
            throw new Error(`Login failed with status: ${response.status}`);
        }

        const data = await response.json();
        
        // 2. Успешно получен ответ: сохраняем токены
        // Auth token сохраняем навсегда
        localStorage.setItem(AUTH_KEY, data.auth_token);
        // Session token используем для всех быстрых запросов
        localStorage.setItem(SESSION_KEY, data.session_token);
        
        // 3. Инициализация UI
        console.log(`✅ Сессия активирована! Пользователь: ${data.username}, Баланс: ${data.balance}`);
        
        // Здесь вы можете вызвать функцию, которая обновит ваш UI
        updateUserInfo(data.username, data.balance); 

    } catch (error) {
        console.error("❌ Критическая ошибка авторизации:", error);
        // Показать сообщение об ошибке пользователю (например, "Сервер недоступен")
    }
}

function updateUserInfo(username, balance) {
    document.getElementById('usernameDisplay').innerText = username;
    document.getElementById('balanceDisplay').innerText = `Balance: ${balance.toFixed(2)}`;
    // После авторизации, разблокируем кнопки ставок
    document.getElementById('placeBet').disabled = false;
    document.getElementById('cashout').disabled = true;
}

document.addEventListener("DOMContentLoaded", () => {
  const placeBetBtn = document.getElementById("placeBet");
  const cashoutBtn = document.getElementById("cashout");
  const betAmountInput = document.getElementById("betAmount");
  const multiplierDisplay = document.getElementById("currentMultiplier");

  let sessionToken = localStorage.getItem("session_token"); // или получи от бэка
  let betPlaced = false;
  let cashedOut = false;

  placeBetBtn.addEventListener("click", async () => {
    const amount = parseFloat(betAmountInput.value);
    if (!amount || amount <= 0) return alert("Enter valid bet amount");

    const payload = {
      bet: {
        amount: amount,
        auto_cashout: null, // или значение из UI
        client_seed: generateClientSeed(),
        session_token: sessionToken
      }
    };

    try {
      const response = await fetch("/api/v1/bets", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (data.success) {
        betPlaced = true;
        cashedOut = false;
        console.log("Bet placed:", data);
      } else {
        alert("Bet failed: " + JSON.stringify(data.errors || data.message));
      }
    } catch (err) {
      console.error("Bet error:", err);
    }
  });

  cashoutBtn.addEventListener("click", () => {
    if (!betPlaced || cashedOut) return;

    // TODO: реализовать кешаут через API или WebSocket
    console.log("Cashout triggered");
    cashedOut = true;
  });

  // WebSocket для получения множителя
  const socket = new WebSocket("ws://localhost:3000/cable");

  socket.onopen = () => {
    socket.send(JSON.stringify({
      command: "subscribe",
      identifier: JSON.stringify({ channel: "AlertsChannel" })
    }));
  };

  socket.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.type === "ping" || !data.message) return;

    const msg = data.message;

    if (msg.multiplier) {
      multiplierDisplay.textContent = `${msg.multiplier.toFixed(2)}x`;
    }

    if (msg.type === "GAME_CRASH") {
      betPlaced = false;
      cashedOut = false;
      console.log("Game crashed at", msg.final_multiplier);
    }
  };

  function generateClientSeed() {
    return Math.random().toString(36).substring(2, 10);
  }
});


// Запускаем процесс при загрузке страницы
document.addEventListener('DOMContentLoaded', initializeSession);