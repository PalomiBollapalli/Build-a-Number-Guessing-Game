#!/bin/bash

secret_number=$((RANDOM % 1000 + 1))
number_of_guesses=0

echo -n "Enter your username: "
IFS= read -r username

player_record=$(psql -X -qAt -v ON_ERROR_STOP=1 -U freecodecamp -d number_guess -v username="$username" <<'SQL'
SELECT games_played || '|' || best_game
FROM users
WHERE username = :'username';
SQL
)

if [[ -z $player_record ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
else
  IFS='|' read -r games_played best_game <<< "$player_record"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"

while true; do
  if ! IFS= read -r guess; then
    exit 1
  fi

  if ! [[ $guess =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  guess=$((10#$guess))
  number_of_guesses=$((number_of_guesses + 1))

  if (( guess == secret_number )); then
    break
  elif (( guess < secret_number )); then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"

psql -X -qAt -v ON_ERROR_STOP=1 -U freecodecamp -d number_guess \
  -v username="$username" -v attempts="$number_of_guesses" <<'SQL'
INSERT INTO users (username, games_played, best_game)
VALUES (:'username', 1, :attempts)
ON CONFLICT (username) DO UPDATE
SET games_played = users.games_played + 1,
    best_game = LEAST(users.best_game, EXCLUDED.best_game);
SQL
