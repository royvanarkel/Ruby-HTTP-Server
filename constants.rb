WEB_ROOT = './public'

CONTENT_TYPE_MAPPING = {
    'html' => 'text/html',
    'txt' => 'text/plain',
    'png' => 'image/png',
    'jpg' => 'image/jpeg',
    'json' => 'application/json',
    'css' => 'text/css'
}

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

ERROR = {
    404 => {code: 404, status: 'Not found'},
    500 => {code: 500, status: 'Internal server error'}
}