##############################################################
# Properties
##############################################################
set AppleScript's text item delimiters to ","

property rowHeaders : "Keyword,Longtail,Searches,Engagement,Competition,Shops Competing,Free Shipping %,Bargain Price,Midrange Price,Premium Price"

property newLine : "\n"

# For testing
property baseUserFile : "base-user-keywords.txt"
property baseFile : "base-keywords.csv"
property newFile : "base-keywords-data.csv"

##############################################################
# HANDLERS - General Constructors
##############################################################

# Load Script
on load_script(_scriptName)
	tell application "Finder"
		set scriptsPath to "scripts:" as string
		set _myPath to container of (path to me) as string
		set _loadPath to (_myPath & scriptsPath & _scriptName) as string
		load script (alias _loadPath)
	end tell
end load_script

# Boolean Checks
on _check(_parent, _child)
	set _script to load_script("_check.scpt")
	tell _script to set a to _check(_parent, _child)
	return a
end _check

# Data Handlers
on _getData(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return a
end _getData

# Run Single Script
on _run(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return
end _run


##############################################################
# HANDLERS - Loop Constructors
##############################################################

# Get Iterative Loop Data
on loop_iterate(a, b, c)
	set _script to load_script("_loop.scpt")
	tell _script to set theList to _loop_iterate(a, b, c)
end loop_iterate

# Get Defined Loop Data
on loop_defined(a, b)
	set _script to load_script("_loop_defined.scpt")
	tell _script to set theList to _loop_defined(a, b)
end loop_defined


##############################################################
# HANDLERS - File Read/Write Constructors
##############################################################

# Save File
on saveFile(theContent, fileName)
	set a to load_script("file_writeFile.scpt")
	tell a to writeFile(theContent, false, fileName) as string
end saveFile

# Apply CSV Headers
on write_headers(newFileName)
	saveFile(rowHeaders & newLine, newFileName) as string
end write_headers


##############################################################
# HANDLERS - List Constructors
##############################################################

# Insert into list
on insertToList(theItem, theList)
	set a to load_script("list_insert_item.scpt")
	tell a to insertItemInList(theItem, theList, 1)
end insertToList

# Remove Duplicates from a List
on list_remove_dupes(theList)
	set a to load_script("list_remove_dupes.scpt")
	tell a to list_remove_dupes(theList)
end list_remove_dupes

# Make List from File
on makeFileList(theFile)
	set theList to {}
	set a to load_script("file_path.scpt")
	set b to load_script("file_writeFile.scpt")
	
	# Set the file path
	tell a to set filePath to setFilePath(theFile)
	
	# Set up the list by reading every paragraph line of the file
	set theList to paragraphs of (read POSIX file filePath)
	return theList
end makeFileList


##############################################################
# DATA ROUTINES
##############################################################

# Get the stat data
on getData(arg)
	set a to load_script("getData.scpt")
	tell a to set b to getData(arg)
	return b
end getData

# Set the input and perform the search
on setInput(theCurrentItem)
	set a to load_script("do_setInput.scpt")
	tell a to set theCurrentItem to setSearchInput("q", theCurrentItem)
end setInput

# Get Word Cloud
on getWordCloud()
	set a to load_script("_loop.scpt")
	tell a to set b to _loop_iterate("querySelectorAll", "#word_cloud span", "innerText", newLine)
	return b
end getWordCloud


##############################################################
# SUBROUTINES
##############################################################

# ----------------------------------------
# Prompt the user to enter a keyword
# ----------------------------------------
on prompt_keyword()
	set a to load_script("ui_keyword.scpt")
	tell a to userKeyword()
end prompt_keyword

# ----------------------------------------
# Sub-routine for setting up a user keyword
# ----------------------------------------
(*	1. Prompt for a keyword
		2. Set the Marmalead input with the keyword
		3. Initiate the search for that keyword *)

on step_keyword()
	set theKeyword to prompt_keyword()
	setInput(theKeyword)
	return theKeyword
end step_keyword

# ----------------------------------------
# Subroutine for setting up the file
# ----------------------------------------
(* 	1. Set the file name based on the user keyword (or passed argument)
		2. Write headers to the file
		3. Return the filename *)

on step_fileSetup(theKeyword)
	set fileName to theKeyword & ".csv"
	saveFile(rowHeaders & newLine, fileName) as string
	return fileName
end step_fileSetup

# ----------------------------------------
# Subroutine for checking data quality
# ----------------------------------------
(*	1. Perform the getData() routine, which gets all the Etsy stats data for a tag
		
		2. The getData() routine returns false if criteria for stats is not fulfilled.
			 If it returns data, or is not false, then we perform the saveFile routine.
		
		NOTE: We use "false" literal to adhere to DRY. We always want to set "getData()" as string when returned.
					As a result, when we receive getData() as "false", it comes through as a literal.
					This literal value is what we need to use in our logic. *)

on check_data_quality(fileName)
	set d to getData(1) as string
	
	if d is not "false" then
		saveFile(d & newLine, fileName) as string
	end if
end check_data_quality

# ----------------------------------------
# Subroutine for checking page load status
# ----------------------------------------
on check_pageLoad()
	_run("_check_loaded.scpt")
end check_pageLoad


############################################################################################################################
############################################################################################################################
############################################################################################################################


##############################################################
# ROUTINE: Process Data from File
##############################################################
on processData_fromFile(theProcessFile, newFileName)
	write_headers(newFileName)
	
	set AppleScript's text item delimiters to ","
	
	# Read existing txt file
	set theList to makeFileList(theProcessFile)
	
	# Create an empty list named "returnList"
	set returnList to {}
	
	# Set a loop for iterating through all the words (separate lines) in the txt file
	repeat with a from 1 to length of theList
		
		# Read the current line from the file
		set theCurrentListItem to item a of theList
		
		# Insert the word into the Marmalead search input and initiate the search
		setInput(theCurrentListItem)
		
		# Wait for the page to load
		check_pageLoad()
		
		# Find the data and filter by quality
		check_data_quality(newFileName)
	end repeat
end processData_fromFile

##############################################################
# ROUTINE: Get word cloud items for each word in file
##############################################################
on process_existing_keywords(baseFile, newFile)
	saveFile("Related Keywords" & newLine, newFile) as string
	set fileList to makeFileList(baseFile)
	
	
	repeat with a from 1 to length of fileList
		set theCurrentListItem to item a of fileList
		set returnList to {}
		setInput(theCurrentListItem)
		
		check_pageLoad()
		set theData to getWordCloud() as string
		
		saveFile(theData & newLine, newFile) as string
	end repeat
end process_existing_keywords


##############################################################
# ROUTINE: Get Word Clouds From User Prompt
##############################################################
on get_from_prompt()
	set theKeyword to step_keyword()
	set fileName to step_fileSetup(theKeyword)
	
	check_pageLoad()
	
	set w to getWordCloud()
	
	set wordCount to length of w
	set progress total steps to wordCount
	set progress completed steps to 0
	set progress description to "Processing Keywords..."
	set progress additional description to "Preparing to process."
	
	check_data_quality(fileName)
	
	repeat with a from 1 to length of w
		set progress additional description to "Processing keyword " & a & " of " & wordCount
		set theCurrentListItem to item a of w
		
		setInput(theCurrentListItem)
		check_pageLoad()
		check_data_quality(fileName)
		
		set progress completed steps to a
	end repeat
	
	# Reset the progress information
	set progress total steps to 0
	set progress completed steps to 0
	set progress description to ""
	set progress additional description to ""
	
	return "Finished."
end get_from_prompt


##############################################################
# CALLS
##############################################################
get_from_prompt()
#processData_fromFile("base-words.txt", "zelda perler art longtail data.csv")
#process_existing_keywords("base-words.txt", "results.csv")

