--uart.setup(0,921600,8,0,1);

--* ******************************************************* *
--ģ������init.lc
--�汾 V0.1
--���ߣ�����
--˵�����豸���� �ļ�
--�洢 FS �ļ��б�
--�ļ��б�
--1��init.lc �����ļ�
--2��LSFP.bin (Lua Script File Packet)   ���нű��� WEB ��Դ�����ļ�
--3��cfg.bin �����ļ�
--* ******************************************************* *



function JudgeField(Field,SrcData)
	if (Field) and ( string.len( Field ) > 0)  then return Field ;
	else return SrcData; end;
end;




--д�����ļ��ĺ���
--�����ļ���Ĭ��Ϊ"cfg.bin"
function Save_config()
	local FileName = "cfg.lua";			--Ĭ�� cfg ����Ϊ cfg.lua , ��׺������ .lua
	
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
	
	node.compile(FileName);																		--���� .lua �ļ������ļ���׺Ϊ .lc
	file.remove("cfg.bin");											--ɾ�� .bin �ļ�
	file.remove(FileName);																		--ɾ�� .lua ��ʱ�ļ�
	file.rename("cfg.lc","cfg.bin");		--�� .lc �ļ�����Ϊ .bin �ļ�

	--�������� cfg.bin
	dofile("cfg.bin");
	return 0;
end;



--���ڽ��ļ����2���Ƽ������ֵ
--������4�ֽ�ת��
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

--���ļ�ͷ�������ļ������ļ�ָ��
--Ҫ���ļ����� =< 4095 �ֽڣ������豸��Դ�����������ַ��������
local function ReadFileHead()
	
	local FileCount = 0;		--�ļ�����
	local PackageVer = 0;		--ѹ�����汾
	local init_LSFPlist = {};
	
	--���ļ�
	file.open("LSFP.bin", "r");			--"LSFP.bin"
	
	--��ȡ�ļ���ʾ
	if file.read(32) == "FountainheadMiniServerFilePacket" then
	
	


		PackageVer = Bin2Num(file.read(2));			--��ð汾
		FileCount = Bin2Num(file.read(2));			--��ð����ļ�����
		
		--ѭ����ȡ�����ļ���Ϣ
		local SubFileName = "";
		for i = 1 , FileCount do
			--Seek ����ʹ�� cur
			if ( file.seek("cur") ) then
				SubFileName = string.gsub( file.read(24) , "%z","") ;		-- �滻 0x00
				
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
	
	--�ر��ļ�
	file.close();	
	return PackageVer,FileCount,init_LSFPlist;
end;


--ȫ�ֺ��� ************************************************
--���δָ���ļ������򷵻� ѹ�����汾
--���ָ���ļ������򷵻�ָ���ļ�������
--�·���ʹ�� node.egc.setmode(node.egc.ALWAYS, 10240); �ַ���������֧�� 10K ����
function ReadFileString(FileName)
	local PackageVer, FileCount, init_LSFPlist = ReadFileHead();							--"LSFP.bin"
	if (FileName) then
		local FileDataTable = {} ;					--����ļ���С
		local Size , SizeBlock =  1 , 1024;
	
		FileName = FileName..".lc";				--  .lc 
		
		--���ļ�
		file.open("LSFP.bin", "r");
		
		
		--�ȶ�λ���ļ���ʼλ��
		file.seek("set",35 + FileCount * 32 +  init_LSFPlist[FileName]["FileStart"])
		
		---ѭ����ȡ�ļ�����Ϊ�ļ����ÿ�ν��ܶ�ȡ 1024 �ֽ�
		Size = init_LSFPlist[FileName]["FileSize"]
		for i = 1 , math.ceil( Size / 1024) do
			--Seek ����ʹ�� cur
			if ( file.seek("cur") ) then
				if Size > 1024 then
					SizeBlock = 1024; Size = Size - SizeBlock;
				else SizeBlock = Size end;
				FileDataTable[i] = file.read(SizeBlock);
			end;
		end;		
		
		--�ر��ļ�
		file.close();
		--loadstring(table.concat( FileDataTable ,""));
--print(FileName)		
		return table.concat( FileDataTable ,"");
	else
		return PackageVer;
	end
end;


--����ʱ��Ҫ�ӳ� 2��
tmr.alarm(0, 2000, tmr.ALARM_SINGLE, function()
	loadstring(ReadFileString("Main"))();
end)


--[[
--���� Main �ļ�
--��ʽ1
--dofile("Main"..string.char(46,108,117,97));

--require("Main")

--��ʽ2
--ReadFileString("Main");
--]]

