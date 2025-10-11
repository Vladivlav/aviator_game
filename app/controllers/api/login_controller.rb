require "ostruct"

module Api
  class LoginController < ApplicationController
    # Мы не используем стандартную аутентификацию before_action здесь,
    # так как цель этого эндпоинта — аутентифицировать пользователя.

    # POST /api/login
    def create
      auth_token = params[:auth_token].to_s.strip
      session_token = params[:session_token].to_s.strip

      # 1. Сначала пытаемся восстановить по БЫСТРОМУ токену (Сценарий 1)
      user = find_active_session(session_token)

      if user
        # 1.1. Найдено в Redis. БЫСТРЫЙ ПУТЬ.
        render json: build_response_data(user), status: :ok
      else
        # 2. Если сессия неактивна, пытаемся восстановить по ДОЛГОСРОЧНОМУ токену (Сценарий 2)
        user = find_and_restore_user(auth_token)

        if user
          # 2.1. Найдено в БД. ВОССТАНОВЛЕНИЕ СЕССИИ.
          render json: build_response_data(user), status: :ok
        else
          # 3. Если ничего не найдено - создаем нового гостя (Сценарий 3)
          user = create_new_guest_user
          render json: build_response_data(user), status: :created
        end
      end
    end

    private

    # --- ЛОГИКА АВТОРИЗАЦИИ / ВОССТАНОВЛЕНИЯ СЕССИИ (Сценарии 1 и 2) ---

    def find_active_session(session_token)
      return nil if session_token.blank?

      user_data_json = REDIS.get("session_token:#{session_token}")

      if user_data_json.present?
        # Успех! Создаем OpenStruct и возвращаем
        user_data = JSON.parse(user_data_json).with_indifferent_access
        user = OpenStruct.new(user_data)
        user.session_token = session_token
        return user
      end
      nil
    end

    # СЦЕНАРИЙ 2: Поиск по auth_token в БД и восстановление (МЕДЛЕННАЯ ПРОВЕРКА)
    def find_and_restore_user(auth_token)
      return nil if auth_token.blank?

      # Вот где мы обращаемся к БД, только если у нас есть auth_token
      user = User.find_by(auth_token: auth_token)

      if user
        # Успех! Нашли в БД. Восстанавливаем сессию.
        restore_session!(user)
        return user
      end
      nil
    end

    def find_or_restore_session(token)
      return nil if token.blank?

      # 1. Сначала ищем в Redis (Сценарий 1: Активная сессия)
      user_id = REDIS.get("session_token:#{token}")

      if user_id.present?
        # Успех! Сессия активна, просто возвращаем пользователя (быстрый путь).
        return User.find_by_id(user_id)
      end

      # 2. Если в Redis нет, ищем в БД по auth_token (Сценарий 2: Старая сессия)
      user = User.find_by(auth_token: token)

      if user
        # Успех! Нашли по долгосрочному токену, теперь нужно восстановить сессию
        restore_session!(user)
        return user
      end

      # Не найдено нигде
      nil
    end

    # --- ЛОГИКА СОЗДАНИЯ НОВОГО ГОСТЯ (Сценарий 3) ---

    def create_new_guest_user
      # Вызываем наш сервис для создания пользователя в БД
      user = GuestUserCreator.call

      # Сразу же создаем для него активную сессию в Redis
      restore_session!(user)

      user
    end

    def restore_session!(user)
        session_token = SecureRandom.urlsafe_base64(32)

        user_data = {
            id: user.id,
            username: user.username,
            # 🚨 ДОБАВЛЯЕМ auth_token В КЭШ
            auth_token: user.auth_token,
            balance: user.balance_persistent.to_f
        }

        REDIS.set("session_token:#{session_token}", user_data.to_json, ex: 3600)

        user.session_token = session_token
    end

    # --- ХЕЛПЕР: Формирование ответа для клиента ---

    def build_response_data(user)
      # Мы должны вернуть ТОЛЬКО ТОТ ТОКЕН, который клиент должен использовать для API

      # Если у пользователя есть session_token (он только что был создан/восстановлен),
      # мы его возвращаем. Если нет, возвращаем auth_token.
      # Но в нашей логике restore_session! всегда отрабатывает,
      # так что session_token должен быть

      balance = user.try(:balance) || user.balance_persistent.to_f

      {
        auth_token: user.auth_token, # Клиент должен сохранить auth_token навсегда
        session_token: user.session_token, # Клиент использует session_token для быстрых запросов
        username: user.username,
        balance: balance
      }
    end
  end
end
