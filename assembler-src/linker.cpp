#include <io.h>
#include <vector>
#include <fstream>
#include <cstring>
#include <iostream>
#include <stdexcept>
using namespace std;

const int UNDEFINED = -1;
const int DATA = 0;
const int TEXT = 1;

struct segment
{
	int type;
	int offset;
	vector<string> codes;
	
	segment()
	{
		type=offset=UNDEFINED;
	}
	
	void print()
	{
		cout<<(type==0?"DATA":"CODE")<<" segment\n";
		cout<<"offset = "<<offset<<'\n';
		for(int i=0;i<codes.size();i++)
			cout<<"line #"<<i<<":\t"<<codes[i]<<'\n'; 
	}
};

vector<string> load_file_list()
{
	_finddata_t filepath;
	char* dir=".\\*.asm";
	long handle;
	
	vector<string> v_file;
	if((handle=_findfirst(dir,&filepath))==-1)
		cout<<"No file is found\n";
	else
		do
		{
			v_file.emplace_back(string(filepath.name));
		}
		while(_findnext(handle,&filepath)==0);
	_findclose(handle);
	return v_file;
}

void lowercase(string &str)
{
	for(int i=0;i<str.length();i++)
		if(str[i]>='A' && str[i]<='Z')
			str[i]=str[i]-'A'+'a';
}

int valueof(string str)
{
	int base=10,res=0;
	int n=str.length();
	
	if(n>2 && str[0]=='0' && str[1]=='x')
		base=16,str=str.substr(2),n-=2;
	if(n>1 && str[n-1]=='b')
	{
		if(base!=16)
			throw "valueof(): base conflict";
		base=2,str=str.substr(0,n-1),n-=1;
	}
	
	for(int i=0;i<n;i++)
	{
		int digit=(str[i]>='0' && str[i]<='9')?str[i]-'0':str[i]-'a';
		if(digit<0 || digit>=base)
			throw "valueof(): invalid value";
		res=res*base+digit;
	}
	return res;
}

int get_offset(string str)
{
	int n=str.length(),l=0,r=n-1;
	while(l<n && (str[l]==' ' || str[l]=='\t'))
		l++;
	while(r>=0 && (str[r]==' ' || str[r]=='\t'))
		r--;
	return (l>r?0:valueof(str.substr(l,r-l+1)));
}

vector<segment> read_file(string filename)
{
	cout<<"filename = "<<filename<<'\n'; 
	ifstream fin(filename.c_str());
	
	string buf;
	vector<string> codes;
	while(getline(fin,buf))
	{
		lowercase(buf);
		codes.emplace_back(buf);
	}
	
	string str;
	segment cur_seg;
	vector<segment> v_seg;
	for(string str: codes)
	{
		if(str.length()>=5)
			if(str.substr(0,5)==".data" || str.substr(0,5)==".text")
			{
				if(cur_seg.type!=UNDEFINED)
					v_seg.push_back(cur_seg);
				
				cur_seg=segment();
				cur_seg.type=(str[1]=='d'?DATA:TEXT);
				cur_seg.offset=get_offset(str.substr(5));
				continue;
			}
		
		if(cur_seg.type==UNDEFINED)
			continue;
		cur_seg.codes.emplace_back(str);
	}
	if(cur_seg.type!=UNDEFINED)
		v_seg.push_back(cur_seg);
	
	fin.close();
	return v_seg;
}

int main()
{
	vector<string> v_file=load_file_list();
	for(string filename: v_file)
	{
		vector<segment> v_seg=read_file(filename);
		for(segment seg: v_seg)
			seg.print();
	}
	return 0;
}
