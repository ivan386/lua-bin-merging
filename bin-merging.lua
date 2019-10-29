

function merge_part(streams_in, buffer_length)
	local out_part
	for _, stream in ipairs(streams_in) do
		local in_part = stream:read(buffer_length)

		if not out_part then
			out_part = in_part -- просто копируем часть из первого файла
		elseif in_part and #in_part > 0 then

 			if #out_part < #in_part then
				out_part, in_part = in_part, out_part
			end
			
			if out_part ~= in_part 	-- данные различаются
				and in_part:find("[^\0]")	-- есть не пустые места в in_part
				and out_part:find("\0", 1, true) -- есть пустые места в out_part
			then 
				local find_index = 1
--[[
```
Функция `string.gsub` подходит для задачи так как найдёт кусочки заполненные нулями и поставит то что передано ей.
```lua
--]]
				out_part = out_part:gsub("\0+", function(zero_string)

					if #in_part < find_index then
						return -- не на что менять
					end
--[[
```
`string.gsub` не передаёт позицию в которой был найдено совпадение. Поэтому делаем параллельный поиск позиции `zero_string` при помощи функции `string.find`. Достаточно найти первый нулевой байт.
```lua
--]]
					local start_index = out_part:find("\0", find_index, true)
					find_index = start_index + #zero_string

--[[
```
Теперь если в `in_part` есть данные для `out_part` копируем их.
```lua
--]]
					if #in_part >= start_index then
						local end_index = start_index + #zero_string - 1
--[[
```
Вырезаем из `in_part` часть соответствующую последовательности нулей.
```lua
--]]
						local part = in_part:sub(start_index, end_index)

						if (part:byte(1) ~= 0) or part:find("[^\0]") then
--[[
```
В `part` есть данные.
```lua
--]]
							if #part == #zero_string then
								return part
							else
--[[
```
`part` оказался меньше чем последовательность нулей. Дополняем его ими.
```lua
--]]
								return part..zero_string:sub(1, end_index - #in_part)
							end
						end
					end
				end)
			end
		end
	end
	return out_part
end

local out_file = table.remove(arg,1)
local in_files = {table.unpack(arg)}
local error_msg

if type(out_file) ~= "string" then
	error_msg = "output file not specified"
end

if (not error_msg) and #in_files <= 1 then
	error_msg = "must be two or more input files"
end

if error_msg then
	io.stderr:write(([[%s

command output_file input_file input_file...

output_file - file were be writen merge of input_files
input_file - input file from get data
]]):format(error_msg))
	os.exit(false)
end 

local streams_in = {}
for _, in_file in pairs(in_files) do
	if type(in_file) == "string" then
		table.insert(streams_in, io.open(in_file, "rb"))
	end
end

local stream_check = io.open(out_file, "rb")
local stream_out
if not stream_check then
	stream_out = io.open(out_file, "wb")
else
	print("File exists. Run file check.")
	
end

local bytes = 0
local buffer_length = 4 * 1024
while true do
	local out_bytes = merge_part(streams_in, buffer_length)
	if (not out_bytes) or #out_bytes == 0 then
		if stream_check then
			local part = stream_check:read(1)
			if part and #part > 0 then
				print("part not match")
			end
		end
		(stream_check or stream_out):close()
		break
	end
	if stream_out then
		stream_out:write(out_bytes)
	elseif stream_check then
		local part = stream_check:read(buffer_length)
		if (not part) or part ~= out_bytes then
			print("part not match")
			break
		end
	end
	
	bytes = bytes + #out_bytes
	io.stderr:write(bytes.."\r")
end