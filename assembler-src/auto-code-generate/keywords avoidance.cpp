#include <map>
#include <cstdio>
#include <vector>
#include <cstring>
#include <iostream>
#include <algorithm>
using namespace std;

typedef pair<int,int> pii;
const int MAX_STR_LEN=100;
const int MAX_NODE_NUM=10000;

int symbol=63;
string full_collec="[a-zA-Z0-9_]";

int mapping[300];
char rmapping[300];
bool init_symbol[300];
bool extra_bslash[300];

int tot=1;
int tag[MAX_NODE_NUM];
int trie[MAX_NODE_NUM][100];

bool pool[100];
char pref[MAX_STR_LEN];

vector<string> solve(int x,int pos,int st_pos)
{
	vector<string> ans;
	if(tag[x] && pos!=st_pos)
		return ans;
	
	memset(pool,false,sizeof(pool));
	
	vector<int> v;
	for(int i=0;i<symbol;i++)
		if(trie[x][i])
			pool[i]=true,v.emplace_back(i);
	
	vector<pii> v_res;
	for(int i=0;i<symbol;)
	{
		while(i<symbol && pool[i])
			i++;
		if(i==symbol)
			break;
		
		int j=i+1;
		while(j<symbol && !pool[j] && !init_symbol[j])
			j++;
		v_res.emplace_back(pii(i,j-1));
		i=j;
	}
	
	if(v.empty())
		return ans;
	
	string expr;
	for(int i=st_pos;i<pos;i++)
		expr=expr+pref[i];
	expr=expr+'[';
	for(pii tmp: v_res)
	{
		char l=rmapping[tmp.first],r=rmapping[tmp.second];
		if(l==r)
		{
			if(extra_bslash[tmp.first])
				expr=expr+'\\';
			expr=expr+l;
		}
		else
			expr=expr+l+'-'+r;
	}
	expr=expr+']';
	ans.emplace_back(expr);
	
	for(int y: v)
	{
		pref[pos]=rmapping[y];
		vector<string> ans_nxt=solve(trie[x][y],pos+1,st_pos);
		ans.insert(ans.end(),ans_nxt.begin(),ans_nxt.end());
	}
	return ans;
}

map<string,vector<string>> combine;

void dfs(int x,int pos)
{
	vector<int> v;
	for(int i=0;i<symbol;i++)
		if(trie[x][i])
			v.emplace_back(i);
	
	if(tag[x])
	{
		string str_pref,expr;
		for(int i=0;i<pos;i++)
			str_pref=str_pref+pref[i];
		
		vector<string> v_mid=solve(x,pos,pos);
		if(v_mid.size()>1)
		{
			expr=expr+'(';
			for(int i=0;i<v_mid.size();i++)
				expr=expr+v_mid[i]+(i+1==v_mid.size()?')':'|');
		}
		else
			if(!v_mid.empty())
				expr=expr+v_mid[0];
		expr=expr+full_collec+(v_mid.empty()?'+':'*');
		combine[expr].emplace_back(str_pref);
	}
	
	for(int y: v)
	{
		pref[pos]=rmapping[y];
		dfs(trie[x][y],pos+1);
	}
}

int n;
char buf[MAX_STR_LEN];

void init()
{
	init_symbol[0]=true;
	for(int i=0;i<26;i++)
		mapping['a'+i]=i,rmapping[i]='a'+i;
	
	init_symbol[26]=true;
	for(int i=0;i<26;i++)
		mapping['A'+i]=26+i,rmapping[26+i]='A'+i;
	
	init_symbol[52]=true;
	for(int i=0;i<10;i++)
		mapping['0'+i]=52+i,rmapping[52+i]='0'+i;
	
	init_symbol[62]=extra_bslash[62]=true;
	mapping['_']=62,rmapping[62]='_';
}

int main()
{
	freopen("keywords.txt","r",stdin);
	
	init();
	
	while(~scanf("%s",buf))
	{
		n=strlen(buf);
		
		int cur=1;
		for(int i=0;i<n;i++)
		{
			int ch=mapping[buf[i]];
			if(!trie[cur][ch])
				trie[cur][ch]=++tot;
			cur=trie[cur][ch];
		}
		tag[cur]=1;
	}
	
/*
	for(int i=1;i<=tot;i++)
		for(int j=0;j<26;j++)
			if(trie[i][j])
				printf("trie[%d][%c]=%d\n",i,char(j+'a'),trie[i][j]);
*/
	
	pref[0]='\0';
	dfs(1,0);
	
	vector<string> items;
	map<string,vector<string>>::iterator it;
	for(it=combine.begin();it!=combine.end();it++)
	{
		string r=it->first;
		vector<string> vl=it->second;
		
		sort(vl.begin(),vl.end());
		reverse(vl.begin(),vl.end());
		
		string item;
		if(vl.size()>1)
			item=item+'(';
		for(int i=0;i+1<vl.size();i++)
		{
			item=item+vl[i]+'|';
			if((i+1)%5==0)
				item=item+'\n';
		}
		item=item+vl.back();
		if(vl.size()>1)
			item=item+')';
		
		item=item+r;
		items.emplace_back(item);
	}
	
	for(int i=0;i<items.size();i++)
	{
		cout<<"(\n"<<items[i]<<"\n)";
		if(i+1<items.size())
			cout<<'|';
		cout<<'\n';
	}
	return 0;
}
