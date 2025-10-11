// src/pages/aviator/main.js

import consumer from "channels/consumer"
import { startGame, endGame, resetGame, startBettingTimerCSS, hideBettingTimer } from "aviator"

// 3. Логика подписки на канал
consumer.subscriptions.create("AlertsChannel", {
    connected() {
        console.log("Подключен к AlertsChannel. Жду очень данных.");
    },

    disconnected() {
        console.warn("Отключен от AlertsChannel.");
    },

    received(data) {
        const display = document.getElementById('currentMultiplier');

        if (data.multiplier) {
            if (data.multiplier == 1.0) {
                startGame();
                hideBettingTimer();
            }
            display.innerText = data.multiplier.toFixed(2) + 'X';
            display.style.color = 'green';
        } else if (data.type == "GAME_CRASH") {
            display.innerText = `CRASH! Финальный множитель: ${data.final_multiplier.toFixed(2)}X`;
            display.style.color = 'red';
            endGame();
        } else if (data.action == "betting_open") {
            resetGame();
            display.innerText = "Время делать ставки, господа!";
            display.style.color = 'blue';
            startBettingTimerCSS();
        } else {
            console.log(data);
        }
    }
});

console.log("Aviator JS-логика инициализирована.");