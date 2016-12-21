
require "thread"


str = "3"

begin
sleep 1
p "loop"
end until str == ("3" || "2")
