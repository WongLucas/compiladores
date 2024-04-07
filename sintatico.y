%{
#include <iostream>
#include <string>
#include <sstream>

#define YYSTYPE atributos
#define TRUE 1
#define FALSE 0

using namespace std;

int var_temp_qnt;
int var_temp_qnt_tipo;

struct atributos
{
	string label;
	string traducao;
};

typedef struct variavel
{
	string nome;
	string tipo;
}var;

var vars[10];

int yylex(void);
void yyerror(string);

string gentempcode();
string gentempcodetipo();

void insere_variavel(var&, string, string);
int busca_variavel(string);

%}

%token TK_NUM
%token TK_MAIN TK_ID TK_TIPO_INT
%token TK_FIM TK_ERROR

%start S

%left '+'
%left '-'
%left '*'
%left '/'

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
			;

E 			: E '+' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| E '*' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " * " + $3.label + ";\n";
			}
			| E '/' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " / " + $3.label + ";\n";
			}
			| TK_ID '=' E
			{
				if(busca_variavel($1.label)){
					$$.label = gentempcode();
					$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
				}else {
           			yyerror("Erro: variável '" + $1.label + "' não foi declarada.");
       			}
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ID
			{
				if (busca_variavel($1.label)) {
					$$.label = gentempcode();
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
			| TK_TIPO_INT TK_ID
			{
				if (!busca_variavel($2.label)) {
					$$.label = gentempcodetipo();
					$$.traducao = "\t" + $$.label + " = " + $2.label + ";\n";
					insere_variavel(vars[var_temp_qnt_tipo-1], $2.label, "int");
				} else {
					yyerror("Erro: variável '" + $2.label + "' já foi declarada.");
				}

			}
			;

%%

#include "lex.yy.c"

int yyparse();

void insere_variavel(var& a, string nome, string tipo)
{
    a.nome = nome;
    a.tipo = tipo;
}

int busca_variavel(string nome)
{
	for(int i = 0; i<var_temp_qnt_tipo ; i++){
		if(nome == vars[i].nome){
			return TRUE;
		}
	}
	return FALSE;
}

string gentempcode()
{
	var_temp_qnt++;
	return "t" + to_string(var_temp_qnt);
}

string gentempcodetipo()
{
	var_temp_qnt_tipo++;
	return "t" + to_string(var_temp_qnt_tipo);
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	var_temp_qnt_tipo = 0;

	yyparse();

	for(int i = 0; i<var_temp_qnt_tipo ; i++){
		cout << "\t" << vars[i].nome << " = " << vars[i].tipo << endl;
	}
	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
