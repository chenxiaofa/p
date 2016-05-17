local t = io.popen('git pull')
local a = t:read("*all")
ngx.say(a)
os.execute('php reload_web.php')

