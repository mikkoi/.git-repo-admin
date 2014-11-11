if [ "$VERBOSE" = "1" ]; then echo "Adding 'anyenv' to the path"; fi
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"


