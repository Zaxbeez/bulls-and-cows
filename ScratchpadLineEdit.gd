extends LineEdit

func _gui_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var unicode = event.unicode
		if unicode > 0:
			var letter = char(unicode).to_upper()
			if letter.is_valid_identifier() and letter.length() == 1:
				text = letter  # overwrite with latest key
				caret_column = 1  # move cursor to end
