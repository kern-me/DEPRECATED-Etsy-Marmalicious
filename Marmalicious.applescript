--------------------------------------------------------
-- Properties
--------------------------------------------------------
set AppleScript's text item delimiters to ","

property rowHeaders : "Keyword,Longtail,Searches,Engagement,Competition,Shops Competing,Free Shipping %,Bargain Price,Midrange Price,Premium Price"

property newLine : "\n"

property baseUserFile : "base-user-keywords.txt"
property baseFile : "base-keywords.csv"
property newFile : "base-keywords-data.csv"

--------------------------------------------------------
-- General Constructor Handlers
--------------------------------------------------------
-- Load Script
on load_script(_scriptName)
	tell application "Finder"
		set scriptsPath to "scripts:" as string
		set _myPath to container of (path to me) as string
		set _loadPath to (_myPath & scriptsPath & _scriptName) as string
		load script (alias _loadPath)
	end tell
end load_script

-- Boolean Checks
on _check(_parent, _child)
	set _script to load_script("_check.scpt")
	tell _script to set a to _check(_parent, _child)
	return a
end _check

-- Data Handlers
on _getData(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return a
end _getData

-- Run Single Script
on _run(_scriptName)
	set _script to load_script(_scriptName)
	set a to run _script
	return
end _run


--------------------------------------------------------
-- Loop Constructor Handlers
--------------------------------------------------------

-- Get Iterative Loop Data
on loop_iterate(a, b, c)
	set _script to load_script("_loop.scpt")
	tell _script to set theList to _loop_iterate(a, b, c)
end loop_iterate

-- Get Defined Loop Data
on loop_defined(a, b)
	set _script to load_script("_loop_defined.scpt")
	tell _script to set theList to _loop_defined(a, b)
end loop_defined

--------------------------------------------------------
-- File Read/Write Constructor Handlers
--------------------------------------------------------

-- Save File
on saveFile(theContent, fileName)
	set a to load_script("file_writeFile.scpt")
	tell a to writeFile(theContent, false, fileName) as string
end saveFile


--------------------------------------------------------
-- List Constructor Handlers
--------------------------------------------------------

-- Insert into list
on insertToList(theItem, theList)
	set a to load_script("list_insert_item.scpt")
	tell a to insertItemInList(theItem, theList, 1)
end insertToList

-- Remove Duplicates from a List
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

--------------------------------------------------------
-- Get Specific Data
--------------------------------------------------------

# Get the stat data
on getData()
	set a to load_script("getData.scpt")
	tell a to set b to getData()
	return b
end getData

# Set the input and perform the search
on do_setInput(theCurrentItem)
	set a to load_script("do_setInput.scpt")
	tell a to set theCurrentItem to setSearchInput("q", theCurrentItem)
end do_setInput

# Get Word Cloud
on getWordCloud()
	set a to load_script("_loop.scpt")
	tell a to set b to _loop_iterate("querySelectorAll", "#word_cloud span", "innerText", newLine)
	return b
end getWordCloud

--------------------------------------------------------
-- Write Headers
--------------------------------------------------------

# Apply CSV Headers
on applyCSVHeaders(newFileName)
	saveFile(rowHeaders & newLine, newFileName) as string
end applyCSVHeaders

# Apply Single Column Header
on applyHeader(newFileName)
	saveFile("Related Keyword" & newLine, newFileName) as string
end applyHeader

--------------------------------------------------------
-- User Prompt | Keyword
--------------------------------------------------------
on prompt_keyword()
	set a to load_script("ui_keyword.scpt")
	tell a to userKeyword()
end prompt_keyword

--------------------------------------------------------
-- Process Data from File
--------------------------------------------------------
on processData_fromFile(theProcessFile, newFileName, setting)
	set AppleScript's text item delimiters to ","
	set theList to makeFileList(theProcessFile)
	set returnList to {}
	
	if setting is 1 then
		applyCSVHeaders(newFileName)
	else if setting is 2 then
		applyHeader(newFileName)
	end if
	
	repeat with a from 1 to length of theList
		set theCurrentListItem to item a of theList
		do_setInput(theCurrentListItem)
		_run("_check_loaded.scpt")
		
		if setting is 1 then
			set theData to getData() as string
			if theData is not false then
				saveFile(theData & newLine, newFileName) as string
			end if
			
		else if setting is 2 then
			set theData to getWordCloud() as string
			if theData is not false then
				saveFile(theData & newLine, newFileName) as string
			end if
		end if
	end repeat
end processData_fromFile

--------------------------------------------------------
-- Process Word Cloud Items
--------------------------------------------------------
(*
	This process gets related keywords (word clouds) for every word in an existing txt file
	
	1. Read existing txt file
	
	2. Create an empty list named "returnList"
	
	3. Set a loop for iterating through all the words
		 (separate lines) in the txt file
	
	4. Read the current line from the file and insert
		 the word into the Marmalead search input
		 
	5. Initiate the search
	
	6. Check that the page had loaded
	
	7. Get the word cloud data
	
	8. Insert the data into "returnList"
*)

--------------------------------------------------------
-- Get related keywords for each word in existing file
--------------------------------------------------------

(* 	Setting Values:

		1 - Saves the related keywords (wordcloud) for each
				baseFile word to disk.
		
		2 - Inserts the related keywords (wordcloud) for each
				baseFile word into a list then returns it. *)

on process_existing_keywords(baseFile, newFile, setting)
	set fileList to makeFileList(baseFile)
	set returnList to {}
	
	if setting is 1 then
		applyHeader(newFile)
	end if
	
	try
		repeat with a from 1 to length of fileList
			set theCurrentListItem to item a of fileList
			do_setInput(theCurrentListItem)
			_run("_check_loaded.scpt")
			set w to getWordCloud()
			
			if setting is 1 then
				set w to w as string
				saveFile(w & newLine, newFile) as string
			else if setting is 2 then
				insertToList(w, returnList)
			end if
		end repeat
		
	on error
		if setting is 2 then
			return returnList
		end if
	end try
	
	if setting is 2 then
		return returnList
	end if
end process_existing_keywords


--------------------------------------------------------
-- Routine: Get Related Keywords
--------------------------------------------------------
on routine_getRelatedKeywords(theNewFile)
	set theData to process_wordCloudItems_fromFile()
	list_remove_dupes(theData)
	set theData to theData as string
	saveFile(theData, theNewFile) as string
end routine_getRelatedKeywords


--------------------------------------------------------
-- Routine: Get Word Clouds From User Prompt
--------------------------------------------------------
on step_keyword()
	set theKeyword to prompt_keyword()
	do_setInput(theKeyword)
	return theKeyword
end step_keyword

--

on step_fileSetup(theKeyword)
	set fileName to theKeyword & ".csv"
	saveFile(rowHeaders & newLine, fileName) as string
	return fileName
end step_fileSetup

--

on check_data_quality(fileName)
	set d to getData() as string
	
	if d is not "false" then
		saveFile(d & newLine, fileName) as string
	end if
end check_data_quality

--

on get_from_prompt()
	set theKeyword to step_keyword()
	set fileName to step_fileSetup(theKeyword)
	set wordCloudList to {}
	
	_run("_check_loaded.scpt")
	
	set w to getWordCloud()
	
	check_data_quality(fileName)
	
	repeat with a from 1 to length of w
		set theCurrentListItem to item a of w
		
		do_setInput(theCurrentListItem)
		_run("_check_loaded.scpt")
		
		check_data_quality(fileName)
	end repeat
end get_from_prompt


--------------------------------------------------------
-- Calls
--------------------------------------------------------
get_from_prompt()

