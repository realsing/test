--uart.setup(0,921600,8,0,1);

--* ******************************************************* *
--模块名：init.lc
--版本 V0.1
--作者：冯鸣
--说明：设备启动 文件
--存储 FS 文件列表
--文件列表：
--1、init.lc 启动文件
--2、LSFP.bin (Lua Script File Packet)   所有脚本及 WEB 资源整合文件
--3、cfg.bin 配置文件
--* ******************************************************* *



function JudgeField(Field,SrcData)
	if (Field) and ( string.len( Field ) > 0)  then return Field ;
	else return SrcData; end;
end;




--写配置文件的函数
--配置文件名默认为"cfg.bin"
function Save_config()
	local FileName = "cfg.lua";			--默认 cfg 名称为 cfg.lua , 后缀必须是 .lua
	
	file.open(FileName,"w")
	file.write("cfg_Parameter = {\r\n")

	for k,v in pairs(cfg_Parameter) do  
		
		if type(v) == "table" then
			file.write("\t"..k.." = {\r\n")
			for k1,v1 in pairs(v) do  
				if type(v1) == "number" then
					file.write("\t\t"..k1.." = "..v1.." ,\r\n")
				else
					file.write("\t\t"..k1.." = \""..v1.."\" ,\r\n")
				end
			end;
			file.write("\t\t},\r\n")
		else
			if type(v) == "number" then
				file.write("\t"..k.." = "..v.." ,\r\n")
			else
				file.write("\t"..k.." = \""..v.."\" ,\r\n")
			end		
		end;
	end
	file.write("}\r\n")
	file.close();
	
	node.compile(FileName);																		--编译 .lua 文件，新文件后缀为 .lc
	file.remove("cfg.bin");											--删除 .bin 文件
	file.remove(FileName);																		--删除 .lua 临时文件
	file.rename("cfg.lc","cfg.bin");		--将 .lc 文件改名为 .bin 文件

	--重新载入 cfg.bin
	dofile("cfg.bin");
	return 0;
end;



--用于将文件里的2进制计算成数值
--最多接收4字节转换
local function Bin2Num(BinData)
	local DataLength = string.len(BinData);
	local Total = 0;
	for i = 1 , DataLength do
		if i == 1 then 
			Total = Total + string.byte(BinData,i)
		else
			Total = Total + string.byte(BinData,i) * (256 ^ (i-1))
		end;
	end;
	return Total;
end;

--读文件头，包括文件名和文件指针
--要求文件必须 =< 4095 字节，否则设备资源不够，返回字符串会溢出
local function ReadFileHead()
	
	local FileCount = 0;		--文件数量
	local PackageVer = 0;		--压缩包版本
	local init_LSFPlist = {};
	
	--打开文件
	file.open("LSFP.bin", "r");			--"LSFP.bin"
	
	--读取文件标示
	if file.read(32) == "FountainheadMiniServerFilePacket" then
	
	


		PackageVer = Bin2Num(file.read(2));			--获得版本
		FileCount = Bin2Num(file.read(2));			--获得包里文件数量
		
		--循环读取单个文件信息
		local SubFileName = "";
		for i = 1 , FileCount do
			--Seek 参数使用 cur
			if ( file.seek("cur") ) then
				SubFileName = string.gsub( file.read(24) , "%z","") ;		-- 替换 0x00
				
				--print(SubFileName)
				init_LSFPlist[SubFileName] = {};
				
				init_LSFPlist[SubFileName]["FileType"] = Bin2Num(file.read(2));
				--print("---->FileType =",init_LSFPlist[SubFileName]["FileType"])
				
				init_LSFPlist[SubFileName]["FileStart"] = Bin2Num(file.read(4));
				--print(SubFileName,"---->FileStart = ",init_LSFPlist[SubFileName]["FileStart"])
				
				init_LSFPlist[SubFileName]["FileSize"]  = Bin2Num(file.read(2))
				--print("---->FileSize = ",init_LSFPlist[SubFileName]["FileSize"])
			end;
		end;
	else
--print("File is corrupted!")
	end;
	
	--关闭文件
	file.close();	
	return PackageVer,FileCount,init_LSFPlist;
end;


--全局函数 ************************************************
--如果未指定文件名，则返回 压缩包版本
--如果指定文件名，则返回指定文件的数据
--新方法使用 node.egc.setmode(node.egc.ALWAYS, 10240); 字符串最大可以支持 10K 数据
function ReadFileString(FileName)
	local PackageVer, FileCount, init_LSFPlist = ReadFileHead();							--"LSFP.bin"
	if (FileName) then
		local FileDataTable = {} ;					--存放文件大小
		local Size , SizeBlock =  1 , 1024;
	
		FileName = FileName..".lc";				--  .lc 
		
		--打开文件
		file.open("LSFP.bin", "r");
		
		
		--先定位到文件起始位置
		file.seek("set",35 + FileCount * 32 +  init_LSFPlist[FileName]["FileStart"])
		
		---循环读取文件，因为文件最大每次仅能读取 1024 字节
		Size = init_LSFPlist[FileName]["FileSize"]
		for i = 1 , math.ceil( Size / 1024) do
			--Seek 参数使用 cur
			if ( file.seek("cur") ) then
				if Size > 1024 then
					SizeBlock = 1024; Size = Size - SizeBlock;
				else SizeBlock = Size end;
				FileDataTable[i] = file.read(SizeBlock);
			end;
		end;		
		
		--关闭文件
		file.close();
		--loadstring(table.concat( FileDataTable ,""));
--print(FileName)		
		return table.concat( FileDataTable ,"");
	else
		return PackageVer;
	end
end;


--启动时需要延迟 2秒
tmr.alarm(0, 2000, tmr.ALARM_SINGLE, function()
	loadstring(ReadFileString("Main"))();
end)


--[[
--启动 Main 文件
--方式1
--dofile("Main"..string.char(46,108,117,97));

--require("Main")

--方式2
--ReadFileString("Main");
--]]

