%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*

%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"		{ yylval.tipo = "int"; return TK_TIPO_INT;}

"float"     { yylval.tipo = "float"; return TK_TIPO_FLOAT;}

"bool"		{  yylval.tipo = "bool"; return TK_TIPO_BOOLEAN;}

"char"		{  yylval.tipo = "char"; return TK_TIPO_CHAR;}

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

"true"|"false" { yylval.label = yytext; return TK_BOOL;}
{CHAR}      { yylval.label = yytext; return TK_CHAR; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{NUM}		{ yylval.label = yytext; return TK_NUM; }

.			{ *yytext; }

%%
