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

"int"		{return TK_TIPO_INT;}

"float"     {return TK_TIPO_FLOAT;}

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{REAL}		{ yylval.label = yytext; yylval.tipo = "float"; return TK_REAL; }

.			{ *yytext; }

%%
