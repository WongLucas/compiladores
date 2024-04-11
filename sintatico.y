%{
#include <iostream>
#include <string>
#include <sstream>

#define YYSTYPE atributos
#define TRUE 1
#define FALSE 0

using namespace std;

int var_temp_qnt;
int var_temp_qnt_int;
int var_temp_qnt_float;

struct atributos
{
	string label;
	string traducao;
};

struct variavel
{
	string nome;
	string tipo;
};

struct variavel vars[10];

int yylex(void);
void yyerror(string);

int buscaVariavel(string);
void insere_variavel(variavel&, string, string);
string gentempcode(string);
%}

%token TK_NUM
%token TK_MAIN TK_ID TK_TIPO_INT
%token TK_FIM TK_ERROR

%start S

%left '+'

%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				string codigo = "/*Compilador FOCA*/\n"
								"#include <iostream>\n"
								"#include<string.h>\n"
								"#include<stdio.h>\n"
								"int main(void) {\n";

				codigo += $5.traducao;
								
				codigo += 	"\treturn 0;"
							"\n}";

				cout << codigo << endl;
			}
			;

BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
			}
			;

COMANDOS	: COMANDO COMANDOS
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;

COMANDO 	: E ';'
			{
				$$ = $1;
			}
			| DECLARACAO ';'
			{
				$$ = $1;
			}
			;

DECLARACAO	: TK_TIPO_INT TK_ID
			{
				if (!buscaVariavel($2.label)) {
					$$.label = gentempcode("int");
					insere_variavel(vars[var_temp_qnt], $2.label, "int");
				} else {
					yyerror("Erro: variável '" + $2.label + "' já foi declarada.");
				}
			}
			;

E 			: E '+' E
			{
				$$.label = gentempcode("int");
				insere_variavel(vars[var_temp_qnt], $$.label, "int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			/*| E '-' E
			{
				$$.label = gentempcode("int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}*/
			| TK_ID '=' E
			{
				if (buscaVariavel($1.label)) {
					$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
				} else {
					yyerror("Erro: variável '" + $2.label + "' não foi declarada.");
				}
			}
			| TK_NUM
			{
				$$.label = gentempcode("int");
				insere_variavel(vars[var_temp_qnt], $$.label, "int");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ID
			{
				if (buscaVariavel($1.label)) {
					$$.label = gentempcode("int");
					insere_variavel(vars[var_temp_qnt], $$.label, "int");
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				} else {
					yyerror("Erro: variável '" + $1.label + "' não foi declarada.");
				}
			}
			| '(' E ')'
			{
				$$.label = $2.label;
				$$.traducao = $2.traducao;
			}
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode(string tipo)
{
	if(tipo == "int"){
		var_temp_qnt_int++;
	}else if(tipo == "float"){
		var_temp_qnt_float++;
	}
	return "t" + to_string(var_temp_qnt);
}

int buscaVariavel(string nome)
{
	for(int i = 0; i < var_temp_qnt; i++){
		if(nome == vars[i].nome){
			return TRUE;
		};
	}
	return FALSE;
}

void insere_variavel(variavel& a, string nome, string tipo)
{
    a.nome = nome;
    a.tipo = tipo;
	var_temp_qnt++;
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	var_temp_qnt_int = 0;
	var_temp_qnt_float = 0;

	yyparse();

	for(int i = 0; i< var_temp_qnt; i++){
		cout << vars[i].tipo << " " << vars[i].nome << ";" <<endl;
	}
	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
