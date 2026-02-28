.PHONY: run-dev run-staging run-prod l10n test analyze test-staging test-prod

# Pass -d <device-id> to specify a device, e.g.: make run-dev ARGS="-d emulator-5554"
# Run `flutter devices` to list available devices.
run-dev:
	flutter run \
		--dart-define=ENV=dev \
		--dart-define=API_URL=http://localhost:3000

run-staging:
	flutter run \
		--dart-define=ENV=staging \
		--dart-define=API_URL=https://staging-api.gymhero.app

run-prod:
	flutter run \
		--dart-define=ENV=prod \
		--dart-define=API_URL=https://api.gymhero.app

l10n:
	flutter gen-l10n

test:
	flutter test

test-staging:
	flutter test \
		--dart-define=ENV=staging \
		--dart-define=API_URL=https://staging-api.gymhero.app

test-prod:
	flutter test \
		--dart-define=ENV=prod \
		--dart-define=API_URL=https://api.gymhero.app

analyze:
	flutter analyze
