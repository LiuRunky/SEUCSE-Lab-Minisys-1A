#include <vector>
#include <fstream>
#include <cstring>
#include <iostream>
#include <algorithm>
using namespace std;

vector<string> v[4];

int main()
{
	ifstream fin("dmem32.coe");
	
	string line;
	int line_count=0;
	while(getline(fin,line))
	{
		line_count++;
		if(line_count<=2)
			for(int i=0;i<4;i++)
				v[i].push_back(line);
		else
			for(int i=0;i<4;i++)
			{
				int l=6-i*2,r=7-i*2;
				v[i].emplace_back(line.substr(l,r-l+1)+',');
			}
	}
	fin.close();
	
	for(int i=0;i<4;i++)
		v[i].back().back()=';';
	
	for(int i=0;i<4;i++)
	{
		string filename="dmem32_";
		filename=filename+char('0'+i);
		filename=filename+".coe";
		
		ofstream fout(filename.c_str());
		
		for(string line: v[i])
			fout<<line<<'\n';
		
		fout.close();
	}
	return 0;
}
