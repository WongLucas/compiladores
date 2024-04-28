%option yylineno

%{
#include <string>

%}

ESPACO [ \t]
FIM_LINHA [\n]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*
COMENT ("//"(.*))|("/\*"(.|{FIM_LINHA})*"*/")

%%

{FIM_LINHA}	{num_linha = yylineno;}

{DELIM} 	{}

{COMENT}    {num_linha = yylineno;}

"main"		{ return TK_MAIN;}

"int"		{ yylval.tipo = "int"; return TK_TIPO_INT;}

"float"     { yylval.tipo = "float"; return TK_TIPO_FLOAT;}

"bool"		{  yylval.tipo = "bool"; return TK_TIPO_BOOLEAN;}

"char"		{  yylval.tipo = "char"; return TK_TIPO_CHAR;}

"=="		{  return TK_IGUAL;}

"!="		{  return TK_DIF;}

"<="|">="|[<>]	{ yylval.label = yytext; return TK_RELACIONAL;}

[(){}[\];,]	{ return *yytext; }

[+\-*/%]	{ return *yytext; }

"="		    { return '='; }

{NUM}		    { yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
"true"|"false"  { yylval.label = yytext; yylval.tipo = "bool"; return TK_BOOL;}
{CHAR}          { yylval.label = yytext; yylval.tipo = "char"; return TK_CHAR; }
{REAL}		    { yylval.label = yytext; yylval.tipo = "float"; return TK_REAL; }
{ID}		    { yylval.label = yytext; return TK_ID; }


.			{ *yytext; }

%%
