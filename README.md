package to parse the url to a recording  created on a BeyonWiz PVR which is enigma2 based.
Breaks the recording URL into path elements and decodes the filename into 

 - date time
 - channel name
 - program name
 - series episode
 
 only the program name is required, all other fields are (and returned as) optional.
 
 The return date is UTC based.
 
 
