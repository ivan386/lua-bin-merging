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

local stream_out = io.open(out_file, "wb")

local bytes = 0
local buffer_length = 500000
while true do
	local out_bytes = {}
	for _, stream in ipairs(streams_in) do
		local readen_bytes = stream:read(buffer_length)
		
		if readen_bytes and #readen_bytes > 0 then
			for i = 1, #readen_bytes do
				if (not out_bytes[i]) 
					or ( out_bytes[i] == 0 and readen_bytes:byte(i) ~= 0 ) 
				then
					out_bytes[i] = readen_bytes:byte(i)
				end
			end
		end
	end
	if #out_bytes == 0 then
		stream_out:close()
		break
	end
	stream_out:write(string.char(table.unpack(out_bytes)))
	bytes = bytes + #out_bytes
	io.stderr:write(bytes.."\r")
end