#include <io.h>
#include <cstdio>
#include <vector>
#include <fstream>
#include <sstream>
#include <cstring>
#include <iostream>
#include <algorithm>
using namespace std;



//data structure definitions
struct Variable
{
	string name;
	int start_offset,end_offset;
	
	Variable(string _name,int _start_offset,int _end_offset)
	{
		name=_name,start_offset=_start_offset,end_offset=_end_offset;
	}
};

struct CodeSegment
{
	int offset;
	string filename;
	vector<string> codes;
	vector<Variable> variables;
};

struct DataEntry
{
	int value,width,offset;
	
	DataEntry(int _value,int _width,int _offset)
	{
		value=_value,width=_width,offset=_offset;
	}
};

struct DataSegment
{
	int offset;
	string filename;
	vector<Variable> variables;
	vector<DataEntry> entries;
};

vector<CodeSegment> codesegs;
vector<DataSegment> datasegs;

int dataseg_offset=0;
string dataseg_coe;


/*****functions*****/
//convert uppercase to lowercase
void lowercase(string &str)
{
	for(int i=0;i<str.length();i++)
		if(str[i]>='A' && str[i]<='Z')
			str[i]=str[i]-'A'+'a';
}

//get value of str in decimal
int valueof(string str)
{
	int base=10,res=0;
	int n=str.length();
	
	if(n>2 && str[0]=='0' && str[1]=='x')
		base=16,str=str.substr(2),n-=2;
	if(n>1 && str[n-1]=='b')
	{
		if(base==16)
			throw "valueof(): base conflict";
		base=2,str=str.substr(0,n-1),n-=1;
	}
	
	for(int i=0;i<n;i++)
	{
		int digit=(str[i]>='0' && str[i]<='9')?str[i]-'0':str[i]-'a'+10;
		if(digit<0 || digit>=base)
			throw "valueof(): invalid value";
		res=res*base+digit;
	}
	return res;
}

//convert decimal to hexadecimal (without prefix '0x')
string tohex(int value,int width)
{
	string res;
	for(int i=0;i<width;i++)
	{
		int digit=value%16;
		res=res+char(digit<10?'0'+digit:'a'+digit-10);
		value/=16;
	}
	return res;
}

//load *.txt from current path
vector<string> load_file_list()
{
	_finddata_t filepath;
	char* dir=".\\*.txt";
	long handle;
	
	vector<string> vfile;
	if((handle=_findfirst(dir,&filepath))==-1)
		cout<<"No file is found\n";
	else
		do
		{
			vfile.emplace_back(string(filepath.name));
		}
		while(_findnext(handle,&filepath)==0);
	_findclose(handle);
	return vfile;
}

//rearrange bios and main to first two
vector<string> rearrange(vector<string> v)
{
	vector<string> res;
	
	vector<pair<int,string>> vec;
	for(string str: v)
		if(str.substr(0,4)=="bios")
			vec.push_back(pair<int,string>(1,str));
		else if(str.substr(0,4)=="main")
			vec.push_back(pair<int,string>(2,str));
		else
			vec.push_back(pair<int,string>(3,str));
	
	sort(vec.begin(),vec.end());
	
	for(pair<int,string> temp: vec)
		res.push_back(temp.second);
	return res;
}

//load *_code_output.txt
void load_code(string filename,string filepath)
{
	CodeSegment cur;
	cur.filename=filename,cur.offset=0;
	
	ifstream fin(filepath.c_str());
	
	string line;
	//readin preseted offset
	getline(fin,line);
	if(line!="\\\\segment offset")
	{
		cout<<"wrong format of data output \""<<filepath<<"\" #0\n";
		return;
	}
	else
	{
		getline(fin,line);
		//always 4B, so here offset means line number
		cur.offset=valueof(line)/4;
	}
	
	getline(fin,line);
	if(line!="\\\\variable definition in format of [name, end_offset]")
	{
		cout<<"wrong format of code output \""<<filepath<<"\" #1\n";
		return;
	}
	
	//readin variable definintions
	while(getline(fin,line))
	{
		if(line=="\\\\code storage info in format of [code]")
			break;
		stringstream ss;
		ss<<line;
		string name;
		int end_offset;
		ss>>name>>end_offset;
		
		int start_offset=cur.variables.empty()?0:cur.variables.back().end_offset;
		cur.variables.push_back(Variable(name,start_offset,end_offset));
	}
	if(line!="\\\\code storage info in format of [code]")
	{
		cout<<"wrong format of code output \""<<filepath<<"\" #2\n";
		return;
	}
	
	//readin codes
	while(getline(fin,line))
	{
		if(line=="\\\\end of output")
			break;
		cur.codes.push_back(line);
	}
	if(line!="\\\\end of output")
	{
		cout<<"wrong format of code output \""<<filepath<<"\" #3\n";
		return;
	}
	cout<<"successfully load \""<<filepath<<"\"\n";
	
	fin.close();
	codesegs.push_back(cur);
}

//load *_data_output.txt
void load_data(string filename,string filepath)
{
	DataSegment cur;
	cur.filename=filename,cur.offset=0;
	
	ifstream fin(filepath.c_str());
	
	string line;
	//readin preseted offset
	getline(fin,line);
	bool preseted_offset=false;
	if(line!="\\\\segment offset")
	{
		cout<<"wrong format of data output \""<<filepath<<"\" #0\n";
		return;
	}
	else
	{
		getline(fin,line);
		cur.offset=valueof(line);
		if(cur.offset!=0)
			preseted_offset=true;
		else
		{
			dataseg_offset=(dataseg_offset+3)/4*4;
			cur.offset=dataseg_offset;
		}
	}
	
	getline(fin,line);
	if(line!="\\\\variable definition in format of [name, end_offset]")
	{
		cout<<"wrong format of data output \""<<filepath<<"\" #1\n";
		return;
	}
	
	//readin variable definitions
	while(getline(fin,line))
	{
		if(line=="\\\\data storage info in format of [value, width, offset]")
			break;
		stringstream ss;
		ss<<line;
		string name;
		int end_offset;
		ss>>name>>end_offset;
		
		int start_offset=cur.variables.empty()?cur.offset:cur.variables.back().end_offset;
		end_offset+=cur.offset;
		cur.variables.push_back(Variable(name,start_offset,end_offset));
	}
	if(line!="\\\\data storage info in format of [value, width, offset]")
	{
		cout<<"wrong format of data output \""<<filepath<<"\" #2\n";
		return;
	}
	
	//readin data storage
	while(getline(fin,line))
	{
		if(line=="\\\\end of output")
			break;
		stringstream ss;
		ss<<line;
		int value,width,offset;
		ss>>value>>width>>offset;
		
		offset+=cur.offset;
		cur.entries.push_back(DataEntry(value,width,offset));
	}
	if(line!="\\\\end of output")
	{
		cout<<"wrong format of data output \""<<filepath<<"\" #3\n";
		return;
	}
	cout<<"successfully load \""<<filepath<<"\"\n";
	
	fin.close();
	datasegs.push_back(cur);
	if(!preseted_offset)
		dataseg_offset=cur.variables.empty()?dataseg_offset:cur.variables.back().end_offset;
}

//load according to type
void load_file(string filepath)
{
	//fixed suffix "_data/code_output.txt", length=16
	if(filepath.length()<16 || filepath.substr(filepath.length()-11,11)!="_output.txt")
		return;
	string filename=filepath.substr(0,filepath.length()-16);
	string filetype=filepath.substr(filepath.length()-15,4);
	
	if(filetype=="code")
		load_code(filename,filepath);
	else if(filetype=="data")
		load_data(filename,filepath);
	else
		cout<<"unrecognized format\n";
}

//compare code segments by offset
inline bool cmp(const CodeSegment &X,const CodeSegment &Y)
{
	return X.offset<Y.offset;
}

int main()
{
	//dataseg_coe initialize
	dataseg_coe="0";
	for(int i=1;i<=17;i++)
		dataseg_coe=dataseg_coe+dataseg_coe;
	
	//load *_output.txt file list and rearrange
	vector<string> file_list=load_file_list();
	file_list=rearrange(file_list);
	
	//load file
	for(string filepath: file_list)
		load_file(filepath);
	
	//generate .coe file for data segment
	for(int i=0;i<datasegs.size();i++)
		for(int j=0;j<datasegs[i].entries.size();j++)
		{
			DataEntry cur=datasegs[i].entries[j];
			string tmp=tohex(cur.value,cur.width*2);
			for(int k=0;k<cur.width*2;k++)
				dataseg_coe[cur.offset*2+k]=tmp[k];
		}
	
	//output .coe file for data segment
	ofstream fout("dmem32.coe");
	fout<<"memory_initialization_radix = 16;\n";
	fout<<"memory_initialization_vector =\n";
	for(int i=0;i<16384;i++)
	{
		string tmp=dataseg_coe.substr(i*8,8);
		for(int j=0;j<4;j++)
			swap(tmp[j],tmp[7-j]);
		fout<<tmp<<(i+1>=16384?';':',')<<'\n';
	}
	fout.close();
	
	//rearrange offset and sort code segment
	//assume total applications not exceed 15
	sort(codesegs.begin(),codesegs.end(),cmp);
	
	for(int i=0;i<codesegs.size();i++)
		if(codesegs[i].offset==0)
		{
			string tmp="0x0000";
			tmp[3]=(i<10?'0'+i:'a'+i-10);
			cout<<tmp<<endl; 
			codesegs[i].offset=valueof(tmp);
		}
	sort(codesegs.begin(),codesegs.end(),cmp);
	
	//combine all code segments into one
	vector<string> linked_codes;
	vector<Variable> linked_variables;
	for(int i=0,j=0;i<16384;i++)
	{
		if(j+1<codesegs.size() && i==codesegs[j+1].offset)
			j++;
		
		if(i<codesegs[j].offset+codesegs[j].codes.size())
			linked_codes.emplace_back(codesegs[j].codes[i-codesegs[j].offset]);
		else
			linked_codes.emplace_back("nop");
	}
	for(int i=0;i<datasegs.size();i++)
		for(int j=0;j<datasegs[i].variables.size();j++)
			linked_variables.push_back(datasegs[i].variables[j]);
	
	//output linked code
	fout.open("linked.txt");
	fout<<"\\\\variable definition\n";
	for(int i=0;i<linked_variables.size();i++)
		fout<<linked_variables[i].name<<' '<<linked_variables[i].start_offset<<'\n';
	fout<<"\\\\code start from here\n";
	fout<<".text 0\n"; 
	for(int i=0;i<linked_codes.size();i++)
		fout<<linked_codes[i]/*<<" #"<<i*/<<'\n';
	fout.close();
	
	return 0;
}
