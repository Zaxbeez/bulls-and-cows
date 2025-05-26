extends Node

@onready var guess_input = $"ColorRect/Columns/GuessPanel/History Group/Top Row/GuessInput"
@onready var submit_button = $"ColorRect/Columns/GuessPanel/History Group/Top Row/SubmitButton"
@onready var guess_list = $"ColorRect/Columns/GuessPanel/History Group/ScrollContainer/GuessList"
@onready var new_word_button = $"ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/New Game"
@onready var alphabet_buttons = $ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/AlphabetPanel/GridContainer.get_children()
@onready var theory_slots = $ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/HBoxContainer.get_children()
@onready var scratchpad_slots = $ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/GridContainer.get_children()

var word_to_guess = ""
var word_list = []
var guess_history= []

func _ready():
	load_words()
	pick_random_word()
	submit_button.pressed.connect(on_submit_guess)
	#Auto-Capitalize Guess Inputs
	guess_input.text_changed.connect(func(new_text):
			var pos = guess_input.caret_column
			guess_input.text = new_text.to_upper()
			guess_input.caret_column = pos
			)
	guess_input.text_submitted.connect(on_enter_pressed)
	#Auto-Capitalize Theory and replace existing letters
	for slot in theory_slots:
		if slot is LineEdit:
			slot.text_changed.connect(func(new_text):
				if new_text.length() > 0:
					slot.text = new_text[-1].to_upper())
	#Auto-Capitalize Scratchpad and replace existing letters
	for slot in scratchpad_slots:
		if slot is LineEdit:
			slot.text_changed.connect(func(new_text):
				if new_text.length() > 0:
					slot.text = new_text[-1].to_upper())

	clear_history()
	add_guess_line("[b]Game started![/b] Enter your 5-letter guess.")
	setup_alphabet_buttons()
	new_word_button.pressed.connect(on_new_word_pressed)

func load_words():
	var file = FileAccess.open("res://words.txt", FileAccess.READ)
	while not file.eof_reached():
		var word = file.get_line().strip_edges()
		if word.length() == 5 and has_unique_letters(word):
			word_list.append(word.to_upper())
	file.close()

func pick_random_word():
	word_to_guess = word_list[randi() % word_list.size()]
	print("Secret word:", word_to_guess)

func on_submit_guess():
	var guess = guess_input.text.to_upper()
	if guess.length() != 5:
		add_guess_line("[color=red]Word must have 5 letters[/color]")
		return
	if not has_unique_letters(guess):
		add_guess_line("[color=red]Letters must be unique[/color]")
	if not word_list.has(guess):
		add_guess_line("[color=red]That is not a valid word[/color]")
		return
	var result = calculate_bulls_and_cows(guess, word_to_guess)
	var bulls = result[0]
	var cows = result[1]
	add_guess_line_with_colored_letters(guess, bulls, cows)
	guess_input.text = ""
	guess_history.append({"guess": guess, "bulls": bulls, "cows": cows})
	refresh_history_display()
	if bulls == 5:
		add_guess_line("[b][color=green]You win! The word was " + word_to_guess + "![/color][/b]")
		submit_button.disabled = true

func calculate_bulls_and_cows(guess: String, target: String) -> Array:
	var bulls = 0
	var cows = 0
	for i in range(guess.length()):
		if guess[i] == target[i]:
			bulls += 1
		elif target.contains(guess[i]):
			cows += 1
	return [bulls, cows]

func has_unique_letters(word: String) -> bool:
	var seen := {}
	for c in word:
		if c in seen:
			return false
		seen[c] = true
	return true

func add_guess_line(text: String):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.scroll_following = false
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guess_list.add_child(label)
	# Scroll to bottom
	await get_tree().process_frame
	var scroll = $"ColorRect/Columns/GuessPanel/History Group/ScrollContainer"
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
	
func add_guess_line_with_colored_letters(guess: String, bulls: int, cows: int):
	var colored_guess = ""
	for letter in guess:
		var button = get_alphabet_button(letter)
		if button == null:
			colored_guess +=letter
			continue
			
		var state = button.get_meta("color_state") if button.has_meta("color_state") else 0
		match state:
			1:
				colored_guess += "[color=red]" + letter + "[/color]"
			2:
				colored_guess += "[color=yellow]" + letter + "[/color]"
			_:
				colored_guess += letter
	var line_text = colored_guess + " → Bulls: " + str(bulls) + ", Cows: " + str(cows)
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.scroll_following = false
	label.text = line_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL	
	guess_list.add_child(label)
	
	await get_tree().process_frame
	var scroll = $"ColorRect/Columns/GuessPanel/History Group/ScrollContainer"
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func clear_history():
	for child in guess_list.get_children():
		child.queue_free()

func setup_alphabet_buttons():
	for button in alphabet_buttons:
		button.pressed.connect(on_alphabet_button_pressed.bind(button))
		button.modulate = Color(1,1,1) #Default
		button.set_meta("color_state",0)
		button.focus_mode = Control.FOCUS_NONE
		button.release_focus()		

func on_alphabet_button_pressed(button:Button):
	var state = button.get_meta("color_state") if button.has_meta("color_state") else 0
	state = (state +1) % 3 
	match state:
		0:
			button.modulate = Color(1,1,1) #Default
			button.focus_mode = Control.FOCUS_NONE
			button.release_focus()
		1: 
			button.modulate = Color(1,0,0) #Red
		2:
			button.modulate = Color(1,1,0) #Yellow
	
	button.set_meta("color_state", state)
	
	refresh_history_display()
	
func get_alphabet_button(letter: String) -> Button:
	for button in alphabet_buttons:
		if button.text.strip_edges() == letter:
			return button
	return null
	
	
func refresh_history_display():
	for child in guess_list.get_children():
		child.queue_free()
		
	for entry in guess_history:
		var colored_guess = ""
		for letter in entry["guess"]:
			var button = get_alphabet_button(letter)
			if button ==null:
				colored_guess += letter
				continue
			var state = button.get_meta("color_state") if button.has_meta("color_state") else 0
			match state:
				1:
					colored_guess += "[color=red]" + letter + "[/color]"
				2:
					colored_guess += "[color=yellow]" + letter + "[/color]"
				_:
					colored_guess += letter
					
		var line_text = colored_guess + " → Bulls: " + str(entry["bulls"]) + ", Cows: " + str(entry["cows"])
	
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.scroll_following = false
		label.text = line_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL	
		guess_list.add_child(label)
	
	await get_tree().process_frame
	var scroll = $"ColorRect/Columns/GuessPanel/History Group/ScrollContainer"
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
	
func on_new_word_pressed():
	pick_random_word()
	submit_button.disabled = false
	guess_history.clear()
	clear_history()
	setup_alphabet_buttons()
	for child in $ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/GridContainer.get_children():
		if child is Label or child is LineEdit:
			child.text = ""
	for child in $ColorRect/Columns/WorkingTheoryPanel/VBoxContainer/HBoxContainer.get_children():
		if child is LineEdit:
			child.text = ""
	add_guess_line("[b]New game started![/b] Enter your 5-letter guess.")
	
func on_enter_pressed(_submitted_text):
	on_submit_guess()

func _on_scratchpad_input(slot: LineEdit, event: InputEvent):
	if event is InputEventKey and event.pressend and not event.echo:
		var unicode = event.unicode
		if unicode!= "":
			var letter = unicode.to_upper()
			if letter.is_valid_identifier() and letter.length() ==1:
				slot.text = letter

func handle_scratchpad_input(slot: LineEdit, event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		var unicode = event.unicode
		if unicode != "":
			var letter = unicode.to_upper()
			if letter.is_valid_identifier() and letter.length() == 1:
				slot.text = letter  
