#include <cstdio>
#include <cstring>
#include <iostream>
#include <stdexcept>
using namespace std;

class MyException: public exception
{
public:
    MyException(string str)
		:message(str)
	{}
    ~MyException() throw() {}

    virtual const char* what() const throw () {
        return message.c_str();
    }

private:
    string message;
};

inline string get(string str,int l,int r)
{
	if(r>=str.length())
		throw MyException("get(): r exceed string length");
	if(l>r)
		throw MyException("get(): l > r");
	
	return str.substr(l,r-l+1);
}

inline string hex_to_bin(string hex)
{
	string res;
	for(int i=0;i<hex.length();i++)
	{
		int val=-1;
		if(hex[i]>='0' && hex[i]<='9')
			val=hex[i]-'0';
		if(hex[i]>='a' && hex[i]<='e')
			val=hex[i]-'a'+10;
		if(hex[i]>='A' && hex[i]<='E')
			val=hex[i]-'A'+10;
		
		for(int i=3;i>=0;i--)
			res=res+char(((val>>i)&1)+'0');
	}
	return res;
}

inline string bin_to_hex(string bin)
{
	string res;
	for(int i=bin.length()-1;i>=0;i-=4)
	{
		int bit=0;
		for(int j=max(0,i-3);j<=i;j++)
			bit=bit*2+bin[j]-'0';
		res=char(bit<10?bit+'0':bit-10+'A')+res;
	}
	return "0x"+res;
}

inline int bin_to_int(string bin)
{
	int res=0;
	for(int i=0;i<bin.length();i++)
		res=res*2+bin[i]-'0';
	return res;
}

inline string format(int val)
{
	string res;
	if(!val)
		res="0";
	while(val)
	{
		res=char(val%10+'0')+res;
		val/=10;
	}
	return res;
}

inline string format_bin(string bin)
{
	return format(bin_to_int(bin));
}

string check(string cmd)
{
	string bin=hex_to_bin(cmd);
	
	if(cmd=="00000000")
		return "nop";
	 
	//R-cmd
	{
		string op=get(bin,0,5);
		string rs=get(bin,6,10);
		string rt=get(bin,11,15);
		string rd=get(bin,16,20);
		string shamt=get(bin,21,25);
		string func=get(bin,26,31);
		
		if(op=="000000")
		{
			if(shamt=="00000")
			{
				if(func=="100000")
					return "add $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100001")
					return "addu $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100010")
					return "sub $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100011")
					return "subu $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100100")
					return "and $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100101")
					return "or $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100110")
					return "xor $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="100111")
					return "nor $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="101010")
					return "slt $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="101011")
					return "sltu $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="000100")
					return "sllv $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="000110")
					return "srlv $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				if(func=="000111")
					return "srav $"+format_bin(rd)+", $"+format_bin(rs)+", $"+format_bin(rt);
				
				if(rd=="00000")
				{
					if(func=="011000")
						return "mult $"+format_bin(rs)+", $"+format_bin(rt);
					if(func=="011001")
						return "multu $"+format_bin(rs)+", $"+format_bin(rt);
					if(func=="011010")
						return "div $"+format_bin(rs)+", $"+format_bin(rt);
					if(func=="011011")
						return "divu $"+format_bin(rs)+", $"+format_bin(rt);
				}
				
				if(rs=="00000" && rt=="00000")
				{
					if(func=="010000")
						return "mfhi $"+format_bin(rd);
					if(func=="010010")
						return "mflo $"+format_bin(rd);
				}
				
				if(rt=="00000" && rd=="00000")
				{
					if(func=="010001")
						return "mthi $"+format_bin(rs);
					if(func=="010011")
						return "mtlo $"+format_bin(rs);
				}
				
				if(rt=="00000")
				{
					if(rd=="00000" && func=="001000")
						return "jr $"+format_bin(rs);
					if(func=="001001")
						return "jalr $"+format_bin(rd)+", $"+format_bin(rs);
				}
			}
			
			if(rs=="00000")
			{
				if(func=="000000")
					return "sll $"+format_bin(rd)+", $"+format_bin(rt)+", "+format_bin(shamt);
				if(func=="000010")
					return "srl $"+format_bin(rd)+", $"+format_bin(rt)+", "+format_bin(shamt);
				if(func=="000011")
					return "sra $"+format_bin(rd)+", $"+format_bin(rt)+", "+format_bin(shamt);
			}
			
			if(func=="001101")
				return "break "+get(bin,6,31);
			if(func=="001100")
				return "syscall "+get(bin,6,31);
		}
		
		if(op=="010000")
		{
			if(shamt=="00000" && func=="000000")
			{
				if(rs=="00000")
					return "mfc0 $"+format_bin(rt)+", $"+format_bin(rd)+", 000";
				if(rs=="00100")
					return "mtc0 $"+format_bin(rt)+", $"+format_bin(rd)+", 000";
			}
			if(get(bin,6,31)=="10000000000000000000" && func=="011000")
				return "eret";
		}
	}
	
	//I-cmd
	{
		string op=get(bin,0,5);
		string rs=get(bin,6,10);
		string rt=get(bin,11,15);
		string immediate=get(bin,16,31);
		
		if(op=="001000")
			return "addi $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001001")
			return "addiu $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001100")
			return "andi $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001101")
			return "ori $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001110")
			return "xori $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001111" && rs=="00000")
			return "lui $"+format_bin(rt)+", "+bin_to_hex(immediate);
		if(op=="100000")
			return "lb $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="100100")
			return "lbu $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="100001")
			return "lh $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="100101")
			return "lhu $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="100011")
			return "lw $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="101000")
			return "sb $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="101001")
			return "sh $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="101011")
			return "sw $"+format_bin(rt)+", "+bin_to_hex(immediate)+"($"+format_bin(rs)+")";
		if(op=="000100")
			return "beq $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000101")
			return "bne $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000001" && rt=="00001")
			return "bgez $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000111" && rt=="00000")
			return "bgtz $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000110" && rt=="00000")
			return "blez $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000001" && rt=="00000")
			return "bltz $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000001" && rt=="10001")
			return "bgezal $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="000001" && rt=="10000")
			return "bltzal $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001010")
			return "slti $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
		if(op=="001011")
			return "sltiu $"+format_bin(rt)+", $"+format_bin(rs)+", "+bin_to_hex(immediate);
	}
	
	//J-cmd
	{
		string op=get(bin,0,5);
		string address=get(bin,6,31);
		
		if(op=="000010")
			return "j "+bin_to_hex(address);
		if(op=="000011")
			return "jal "+bin_to_hex(address);
	}
	
	return "unknown command";
}

int main()
{
	ios::sync_with_stdio(false);
	
	string cmd;
	while(cin>>cmd)
	{
		if(cmd.back()==',')
			cmd=get(cmd,0,cmd.length()-2);
		cout<<"> "<<check(cmd)<<'\n';
	}
	return 0;
}
