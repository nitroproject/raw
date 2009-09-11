module Raw

# Various HTTP related constants and utilities.

module Http
  
  # HTTP protocol EOL constants.

  CR = "\x0d"
  LF = "\x0a"
  CRLF = "\x0d\x0a"
  EOL = CRLF

  # Constants for readable code.

  STATUS_OK = 200
  STATUS_PARTIAL_CONTENT = 206
  STATUS_MOVED = 301
  STATUS_REDIRECT = 302
  STATUS_SEE_OTHER = 303        
  STATUS_SEE_OTHER_307 = 307    
  STATUS_NOT_MODIFIED = 304
  STATUS_BAD_REQUEST = 400
  STATUS_AUTH_REQUIRED = 401       
  STATUS_FORBIDDEN = 403           
  STATUS_NOT_FOUND = 404           
  STATUS_METHOD_NOT_ALLOWED = 405  
  STATUS_NOT_ACCEPTABLE = 406      
  STATUS_LENGTH_REQUIRED = 411     
  STATUS_PRECONDITION_FAILED = 412 
  STATUS_SERVER_ERROR = 500        
  STATUS_NOT_IMPLEMENTED = 501    
  STATUS_BAD_GATEWAY = 502         
  STATUS_VARIANT_ALSO_VARIES = 506 

  # Hash to allow id to description maping.

  STATUS_STRINGS = {
    200 => "OK",
    206 => "Partial Content",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See other", # gmosx: VERIFY THIS
    304 => "Not Modified",
    307 => "See other 07", # gmosx: VERIFY THIS
    400 => "Bad Request",
    401 => "Authorization Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    411 => "Length Required",
    412 => "Precondition Failed",
    500 => "Internal Server Error",
    501 => "Method Not Implemented",
    502 => "Bad Gateway",
    506 => "Variant Also Negotiates"
  }
end
  
end
