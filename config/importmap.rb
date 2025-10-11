# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.0.300
pin_all_from "app/javascript/channels", under: "channels"
pin "aviator", to: "aviator.js"
pin "events" # @2.1.0
pin "util" # @2.1.0
