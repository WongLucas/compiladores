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
	string tipo;
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

int busca_variavel(string);
void insere_variavel(variavel&, string, string);

string tipo_variavel(string);

string gentempcode(string);
%}

%token TK_NUM TK_REAL TK_BOOL TK_CHAR
%token TK_MAIN TK_ID 
%token TK_FIM TK_ERROR
%token TK_TIPO_BOOLEAN TK_TIPO_FLOAT TK_TIPO_INT TK_TIPO_CHAR

%start S

%left '+'
%left '*'

%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				string codigo = "/*Compilador FOCA*/\n"
								"#include <iostream>\n"
								"#include<string.h>\n"
								"#include<stdio.h>\n"
								"#define bool int\n"
								"#define true 1\n"
								"#define false 0\n"
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

DECLARACAO	: TIPO TK_ID
			{
				if (!busca_variavel($2.label)) {
					insere_variavel(vars[var_temp_qnt], $2.label, $1.tipo);
				} else {
					yyerror("Erro: variável '" + $2.label + "' já foi declarada.");
				}
			}
			;

TIPO 		: TK_TIPO_INT
			{
			}
			| TK_TIPO_FLOAT
			{
			}
			| TK_TIPO_BOOLEAN
			{
			}
			| TK_TIPO_CHAR
			{
			}
			;

E 			: E '+' E
			{
				if($1.tipo == $3.tipo){
					$$.label = gentempcode($1.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $1.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = " + $1.label + " + " + $3.label + ";\n";
					$$.tipo = $1.tipo;
				}else if($1.tipo == "int" && $3.tipo == "float"){
					$$.label = gentempcode($3.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = (float)" + $1.label + " + " + $3.label + ";\n";
					$$.tipo = $3.tipo;
				}else if($1.tipo == "float" && $3.tipo == "int"){
					$$.label = gentempcode($1.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $1.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = " + $1.label + " + (float)" + $3.label + ";\n";
					$$.tipo = $1.tipo;
				}
			}
			| E '*' E
			{
				if($1.tipo == $3.tipo){
					$$.label = gentempcode($1.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $1.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = " + $1.label + " * " + $3.label + ";\n";
					$$.tipo = $1.tipo;
				}else if($1.tipo == "int" && $3.tipo == "float"){
					$$.label = gentempcode($3.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = (float)" + $1.label + " * " + $3.label + ";\n";
					$$.tipo = $3.tipo;
				}else if($1.tipo == "float" && $3.tipo == "int"){
					$$.label = gentempcode($1.tipo);
					insere_variavel(vars[var_temp_qnt], $$.label, $1.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
						" = " + $1.label + " * (float)" + $3.label + ";\n";
					$$.tipo = $1.tipo;
				}
			}
			/*| E '-' E
			{
				$$.label = gentempcode("int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}*/
			| TK_ID '=' E
			{
				if (busca_variavel($1.label)) {
					if($3.tipo == tipo_variavel($1.label)){
						$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
					} else {
						$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = (" +
						tipo_variavel($1.label) + ")" + $3.label + ";\n";
					}
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
			| TK_REAL
			{
				$$.label = gentempcode("float");
				insere_variavel(vars[var_temp_qnt], $$.label, "float");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";				
			}
			| TK_BOOL
			{
				$$.label = gentempcode("bool");
				insere_variavel(vars[var_temp_qnt], $$.label, "bool");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";				
			}
			| TK_CHAR
			{
				$$.label = gentempcode("char");
				insere_variavel(vars[var_temp_qnt], $$.label, "char");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";				
			}
			| TK_ID
			{
				if (busca_variavel($1.label)) {
					$$.label = gentempcode(tipo_variavel($1.label));
					$$.tipo = tipo_variavel($1.label);
					insere_variavel(vars[var_temp_qnt], $$.label, tipo_variavel($1.label));
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				} else {
					yyerror("Erro: variável '" + $1.label + "' não foi declarada.");
				}
			}
			| '(' E ')'
			{
				$$ = $2;
			}
			| '(' TIPO ')' '(' E ')'
			{
				$$.tipo = $2.tipo;
				$$.label = gentempcode($$.tipo);
				$$.traducao = $5.traducao + "\t" + $$.label + " = (" + $2.tipo + ")" + $5.label + ";\n";
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

int busca_variavel(string nome)
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

string tipo_variavel(string nome){
	for(int i = 0; i < var_temp_qnt; i++){
		if(nome == vars[i].nome){
			return vars[i].tipo;
		};
	}
	return FALSE;
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
