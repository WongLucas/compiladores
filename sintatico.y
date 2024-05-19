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
int num_linha;

bool ocorreu_erro = false;

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

struct variavel vars[20];

string lista_erros = "";
string declaracoes = "";
void insere_declaracoes();

int yylex(void);
void yyerror(string);

void pega_erro(string);

int busca_variavel(string);
void insere_variavel(variavel&, string, string);

void realizarOperacao(string operador, atributos& atributo1, atributos& atributo2, atributos& resultado);

string obter_tipo_variavel(string);

string obter_tipo_operacao(string, string);

string gentempcode(string);

bool operacao_bool_valida(string);
%}

%token TK_NUM TK_REAL TK_BOOL TK_CHAR
%token TK_MAIN TK_ID TK_NOT_ID
%token TK_FIM TK_ERROR
%token TK_TIPO_BOOLEAN TK_TIPO_FLOAT TK_TIPO_INT TK_TIPO_CHAR
%token MAIOR MAIOR_IGUAL MENOR MENOR_IGUAL IGUAL NAO_IGUAL
%token NAO AND OR
%start S

%left OR
%left AND
%left IGUAL NAO_IGUAL
%left MAIOR MAIOR_IGUAL MENOR MENOR_IGUAL 
%left '+' '-'
%left '*' '/'
%left NAO

%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				if(ocorreu_erro){
					yyerror(lista_erros);
				}

				string codigo = "/*Compilador FOCA*/\n"
								"#include <iostream>\n"
								"#include<string.h>\n"
								"#include<stdio.h>\n"
								"#define bool int\n"
								"#define true 1\n"
								"#define false 0\n"
								"int main(void) {\n";
				insere_declaracoes();
				codigo += declaracoes;
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
					pega_erro("linha " + to_string(num_linha) + ": erro: variável '" + $2.label + "' já foi declarada.");
				}
			}
			| TIPO TK_NOT_ID
			{
				yyerror("linha " + to_string(num_linha) + ": Variavel do tipo '" + $2.label + "' é reservada");
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
				realizarOperacao("+", $1, $3, $$);
			}
			| E '-' E
			{
				realizarOperacao("-", $1, $3, $$);
			}
			| E '*' E
			{
				realizarOperacao("*", $1, $3, $$);				
			}
			| E '/' E
			{
				realizarOperacao("/", $1, $3, $$);
			}
			| OPERACAO_RELACIONAL
			{
				$$ = $1;
			}
			| TK_ID '=' E
			{
				if (busca_variavel($1.label)) {
					if($3.tipo == obter_tipo_variavel($1.label)){
						$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
					} else {
						$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = (" +
						obter_tipo_variavel($1.label) + ")" + $3.label + ";\n";
					}
				} else {
					pega_erro("linha " + to_string(num_linha) + ": erro: variável '" + $2.label + "' não foi declarada.");
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
					$$.label = gentempcode(obter_tipo_variavel($1.label));
					$$.tipo = obter_tipo_variavel($1.label);
					insere_variavel(vars[var_temp_qnt], $$.label, obter_tipo_variavel($1.label));
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				} else {
					pega_erro("linha " + to_string(num_linha) + ": erro: variável '" + $1.label + "' não foi declarada.");
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
				insere_variavel(vars[var_temp_qnt], $$.label, $2.tipo);
				$$.traducao = $5.traducao + "\t" + $$.label + " = (" + $2.tipo + ")" + $5.label + ";\n";
			}
			;

OPERACAO_RELACIONAL:
			E MAIOR E{
				realizarOperacao(">", $1, $3, $$);
			}
			| E MAIOR_IGUAL E{
				realizarOperacao(">=", $1, $3, $$);
			}
			| E MENOR E{
				realizarOperacao("<", $1, $3, $$);
			}
			| E MENOR_IGUAL E{
				realizarOperacao("<=", $1, $3, $$);
			}
			| E IGUAL E{
				realizarOperacao("==", $1, $3, $$);
			}
			| E NAO_IGUAL E{
				realizarOperacao("!=", $1, $3, $$);
			}
			| E AND E{
				realizarOperacao("&&", $1, $3, $$);
			}
			| E OR E{
				realizarOperacao("||", $1, $3, $$);
			}
			| NAO E{
				$$.label = gentempcode("bool");
				insere_variavel(vars[var_temp_qnt], $$.label, "bool");
				if($2.tipo != "bool"){
					$$.traducao += $2.traducao + "\t" + $$.label + " = !(bool)" + $2.label + ";\n";
				} else {
					$$.traducao += $2.traducao + "\t" + $$.label + " = !" + $2.label + ";\n";
				}
				$$.tipo = "bool";
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

void insere_declaracoes(){
	for(int i = 0; i < var_temp_qnt; i++){
		declaracoes += "\t" + vars[i].tipo + " " + vars[i].nome + ";\n";
	}
}

string obter_tipo_variavel(string nome){
	for(int i = 0; i < var_temp_qnt; i++){
		if(nome == vars[i].nome){
			return vars[i].tipo;
		};
	}
	return FALSE;
}

bool operacao_bool_valida(string op){
	string operadores[4] = {"||", "&&" , "==", "!="};

	if(op == "||" || op == "&&" || op == "==" || op == "!="){
		return true;
	}
	return false;
}

void realizarOperacao(string operador, atributos& atributo1, atributos& atributo2, atributos& resultado) {
	string tipo_resultado = obter_tipo_operacao(atributo1.tipo, atributo2.tipo);
	struct atributos conversao_auxiliar;

	if(atributo1.tipo != atributo2.tipo && (atributo1.tipo == "bool" || atributo2.tipo == "bool")){
		pega_erro("linha " + to_string(num_linha) + ": erro: tipos de operandos incompatíveis para o operador '" + operador + "'.");
	}
	else if(atributo1.tipo == "bool" && !operacao_bool_valida(operador)){
		pega_erro("linha " + to_string(num_linha) + ": erro: operador '" + operador + "' não definido para o tipo bool.");
	}

	//MesmoTipo Operacao MesmoTipo 
    if (atributo1.tipo == atributo2.tipo) {
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, atributo1.tipo);

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + atributo2.label + ";\n";

        resultado.tipo = tipo_resultado;

	//FLOAT Operacao INT
    } else if (atributo1.tipo == "float" && atributo2.tipo == "int") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);

		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;

	//FLOAT Operacao CHAR
    } else if (atributo1.tipo == "float" && atributo2.tipo == "char") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;

	//FLOAT Operacao BOOL
    } else if (atributo1.tipo == "float" && atributo2.tipo == "bool") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;

	//INT Operacao FLOAT
    } else if (atributo1.tipo == "int" && atributo2.tipo == "float") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
    //INT Operacao CHAR
    } else if (atributo1.tipo == "int" && atributo2.tipo == "char") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;

	//INT Operacao BOOL
    } else if (atributo1.tipo == "int" && atributo2.tipo == "bool") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//CHAR Operacao FLOAT
    } else if (atributo1.tipo == "char" && atributo2.tipo == "float") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//CHAR Operacao INT
	} else if (atributo1.tipo == "char" && atributo2.tipo == "int") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//CHAR Operacao BOOL
    } else if (atributo1.tipo == "char" && atributo2.tipo == "bool") { 
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
		conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo2.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo1.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//BOOL Operacao FLOAT
    } else if (atributo1.tipo == "bool" && atributo2.tipo == "float") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//BOOL Operacao INT
    } else if (atributo1.tipo == "bool" && atributo2.tipo == "int") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
	//BOOL Operacao CHAR	
    } else if (atributo1.tipo == "bool" && atributo2.tipo == "char") {
		conversao_auxiliar.label = gentempcode(tipo_resultado);
		insere_variavel(vars[var_temp_qnt], conversao_auxiliar.label, tipo_resultado);
		resultado.label = gentempcode(tipo_resultado);
        insere_variavel(vars[var_temp_qnt], resultado.label, tipo_resultado);
		
        conversao_auxiliar.traducao = conversao_auxiliar.label + " = " + "(" + tipo_resultado + ")" + atributo1.label + ";\n";

        resultado.traducao = atributo1.traducao + atributo2.traducao + "\t" + conversao_auxiliar.traducao + "\t" +
		resultado.label + " = " + atributo2.label + " " + operador + " " + conversao_auxiliar.label + ";\n";

        resultado.tipo = tipo_resultado;
    }
}

string obter_tipo_operacao(string tipo1, string tipo2) {
	if (tipo1 == tipo2) {
		return tipo1;
	} else if (tipo1 == "float" && tipo2 == "int"){
		return "float";
	} else if (tipo1 == "float" && tipo2 == "char") {
		return "float";
	} else if (tipo1 == "float" && tipo2 == "bool") {
		return "float";
	} else if (tipo1 == "int" && tipo2 == "float") {
		return "float";
	} else if (tipo1 == "int" && tipo2 == "char") {
		return "int";
	} else if (tipo1 == "int" && tipo2 == "bool") {
		return "int";
	} else if (tipo1 == "char" && tipo2 == "float") {
		return "float";
	} else if (tipo1 == "char" && tipo2 == "int") {
		return "int";
	} else if (tipo1 == "char" && tipo2 == "bool") {
		return "char";
	} else if (tipo1 == "bool" && tipo2 == "float") {
		return "float";
	} else if (tipo1 == "bool" && tipo2 == "int") {
		return "int";
	} else if (tipo1 == "bool" && tipo2 == "char") {
		return "char";
	}
	return "";
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	var_temp_qnt_int = 0;
	var_temp_qnt_float = 0;

	yyparse();

	return 0;
}

void pega_erro(string MSG) {
	lista_erros += MSG + "\n";
	ocorreu_erro = true;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
