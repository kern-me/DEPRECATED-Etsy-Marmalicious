--------------------------------------------------------
-- Properties
--------------------------------------------------------
set AppleScript's text item delimiters to ","

property rowHeaders : "Keyword,Longtail,Searches,Engagement,Competition,Shops Competing,Free Shipping %,Bargain Price,Midrange Price,Premium Price"

property newLine : "\n"

--------------------------------------------------------
-- Constructor Handlers
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

-- Save File
on saveFile(theContent, fileName)
	set a to load_script("file_writeFile.scpt")
	tell a to writeFile(theContent, false, fileName) as string
end saveFile

-- Insert into list
on insertToList(theItem, theList)
	set a to load_script("list_insert_item.scpt")
	tell a to insertItemInList(theItem, theList, 1)
end insertToList

# Make List from File
on readFile(theFile)
	set theList to {}
	set a to load_script("file_path.scpt")
	set b to load_script("file_writeFile.scpt")
	
	# Set the file path
	tell a to set filePath to setFilePath(theFile)
	
	# Set up the list by reading every paragraph line of the file
	set theList to paragraphs of (read POSIX file filePath)
	return theList
end readFile

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

# Apply CSV Headers
on applyCSVHeaders(newFileName)
	saveFile(rowHeaders & newLine, newFileName) as string
end applyCSVHeaders

# Apply Single Column Header
on applyHeader(newFileName)
	saveFile("Related Keyword" & newLine, newFileName) as string
end applyHeader

--------------------------------------------------------
-- Process Data from Existing Text File
--------------------------------------------------------

on processTextFile(theProcessFile, theNewFile, dataSetting)
	set AppleScript's text item delimiters to ","
	
	# Read the Existing File
	set theList to readFile(theProcessFile)
	set returnList to {}
	
	# LOOP START
	
	repeat with a from 1 to length of theList
		set theCurrentListItem to item a of theList
		
		# Set the input to the current word line of the file and initiate the search
		do_setInput(theCurrentListItem)
		
		# Wait for the page to load
		_run("_check_loaded.scpt")
		
		if dataSetting is 1 then
			# Get the Etsy Data
			set theData to getData() as string
			saveFile(theData & newLine, theNewFile) as string
		else if dataSetting is 2 then
			set theData to getWordCloud() as string
			saveFile(theData & newLine, theNewFile) as string
		end if
	end repeat
	
end processTextFile

--------------------------------------------------------
-- Process the current Word Cloud (Related Words)
--------------------------------------------------------
on process_wordCloudData(newFileName)
	# Make a list out of the current word cloud
	set theList to loop_iterate("querySelectorAll", "#word_cloud span", "innerText")
	
	# Load the input setting script for future use outside the loop
	set c to load_script("do_setInput.scpt")
	
	# Save the row headers
	
	
	# Start the LOOP
	repeat with a from 1 to length of theList
		set theCurrentListItem to item a of theList
		
		# Set the input to the current word line of the file and initiate the search
		do_setInput(theCurrentListItem)
		
		# Wait for the page to load
		_run("_check_loaded.scpt")
		
		# Get the Etsy Data
		set theData to getData() as string
		
		# Write the Data to File
		saveFile(theData & newLine, newFileName) as string
	end repeat
	return
end process_wordCloudData

#############################

on process_wordCloudItems_fromFile()
	set returnList to {}
	set fileList to readFile("base-keywords.txt")
	set returnList to {}
	
	repeat with a from 1 to length of fileList
		set theCurrentListItem to item a of fileList
		
		do_setInput(theCurrentListItem)
		
		_run("_check_loaded.scpt")
		
		set w to getWordCloud()
		
		insertToList(w, returnList)
	end repeat
	
	return returnList
end process_wordCloudItems_fromFile

on routine_getRelatedKeywords(theNewFile)
	set theData to process_wordCloudItems_fromFile()
	set theData to theData as string
	saveFile(theData, theNewFile) as string
end routine_getRelatedKeywords


--------------------------------------------------------
-- Calls
--------------------------------------------------------
#set currentTag to _getData("getTagName.scpt")
#processWordCloud(currentTag & ".csv")
#processTextFile("base-keywords.txt", "word-cloud-results.csv", 2)
#process_wordCloudItems_fromFile()

#routine_getRelatedKeywords("related-keywords.csv")
processTextFile("related-keywords.txt", "related-keyword-data.csv", 1)
