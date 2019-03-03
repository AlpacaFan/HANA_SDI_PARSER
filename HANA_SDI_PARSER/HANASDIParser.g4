parser grammar HANASDIParser;

options { tokenVocab=HanaSDILexer; }

root
	: selectStatement;
	
	
selectStatement1: 
				  SELECT 
				  SYM_STAR 
				  FROM
				  LIT_DATE;

testLit: literal;

literal: LIT_INT |
		 LIT_DECIMAL |
		 LIT_HEXINT | 
		 LIT_DATE | 
		 LIT_TIME | 
		 LIT_TIMESTAMP|
		 LIT_STRING | 
		 LIT_BINSTRING | 
		 LIT_UNICODESTRING  
		 ;
		 
		 
/* From HANA documentation
 * <expression> ::= <case_expression>
               | <function_expression>
               | <aggregate_expression>
               | (<expression> )
               | ( <subquery> )
               | - <expression>
               | <expression> <operator> <expression>
               | <variable_name>
               | <constant>
               | [<correlation_name>.]<column_name>
 */		 
		 
expression:  caseExpression |
			 aggregateFunctionExpression | 
			 castExpression |
			 functionExpression |
			 subQuery | 
			 bracketExpression |
		    (SYM_PLUS | SYM_MINUS ) expression |         
		    expression ( SYM_STAR | SYM_DIV ) expression |   
		    expression ( SYM_PLUS | SYM_MINUS ) expression |
		    expression  SYM_CONCAT expression  |  
		    expression ( SYM_EQ | SYM_NE | SYM_LT | SYM_LE | SYM_GT | SYM_GE ) expression |
		    expression IS ?NOT NULL | 
		    expression NOT? LIKE expression |   
		    expression NOT? BETWEEN expression AND expression | 
		    expression IN ( SYM_LBRACKET (expressionList|subQuery) SYM_RBRACKET )  | 
		    ( (NOT)? EXISTS subQuery) |
		    // TODO exists predicate
		    NOT expression | 
		    expression AND expression | 
		    expression OR expression | 
		    columnExpression | 
			literal;

expressionList: expression (SYM_COMMA expression )*;
 

caseExpression: simpleCaseExpression |
				searchCaseExpression;

simpleCaseExpression: CASE expression ( WHEN expression THEN expression )+ (ELSE expression)? END;

searchCaseExpression: CASE ( WHEN expression THEN expression )+  (ELSE expression)? END;

/*
 * From HANA Documentation
 *  <aggregate_expression> ::= COUNT(*) | COUNT ( DISTINCT <expression_list> ) | <agg_name> (  [ ALL | DISTINCT ] <expression> ) | STRING_AGG ( <expression> [, <delimiter>] [<aggregate_order_by_clause>]) 
        <agg_name> ::= CORR | CORR_SPEARMAN | COUNT | MIN | MEDIAN | MAX | SUM | AVG | STDDEV | VAR  | STDDEV_POP | VAR_POP | STDDEV_SAMP | VAR_SAMP
        <delimiter> ::= <string_constant>
        <aggregate_order_by_clause> ::= ORDER BY <expression> [ ASC | DESC ] [ NULLS FIRST | NULLS LAST] 
 */
aggregateFunctionExpression: 
			windowFunctionExpression |
			countAllExpression |
		    countDistinctExpression | 
		    aggregationExpression |
		    stringAggregationExpression;

countAllExpression: COUNT SYM_LBRACKET SYM_STAR SYM_RBRACKET;
countDistinctExpression: COUNT SYM_LBRACKET DISTINCT ( SYM_STAR | expressionList) SYM_RBRACKET;

aggregationFunction: CORR | CORR_SPEARMAN | COUNT | MIN | MEDIAN | MAX | SUM | AVG | STDDEV | VAR  | STDDEV_POP | VAR_POP | STDDEV_SAMP | VAR_SAMP;

aggregationExpression: aggregationFunction SYM_LBRACKET ( ALL | DISTINCT )? expression SYM_RBRACKET;
stringAggregationExpression: STRING_AGG SYM_LBRACKET expression (SYM_COMMA stringConstant)? (ORDER BY expression (ASC|DESC)? (NULLS  (FIRST|LAST))? )? SYM_RBRACKET;

windowFunction:  
			BINNING |
			CUBIC_SPLINE_APPROX |
			CUME_DIST |
			DENSE_RANK |
			LAG |
			LEAD |
			LINEAR_APPROX |
			NTILE |
			PERCENT_RANK |
			RANDOM_PARTITION |
			RANK |
			ROW_NUMBER |
			SERIES_FILTER |
			WEIGHTED_AVG |
			CORR |
			CORR_SPEARMAN |
			COUNT |
			FIRST_VALUE |
			NTH_VALUE |
			LAST_VALUE |
			MIN |
			MEDIAN |
			MAX |
			SUM |
			AVG |
			STDDEV |
			VAR;
			
windowFunctionExpression: ( countAllExpression | 
							( windowFunction SYM_LBRACKET expression SYM_RBRACKET )
						  ) 
						  OVER SYM_LBRACKET
						  	( PARTITION BY expressionList) ?
						  	( ORDER BY (expression (ASC|DESC)? (NULLS (FIRST|LAST))? ) (SYM_COMMA expression (ASC|DESC)? (NULLS (FIRST|LAST))? )*  )?
						  SYM_RBRACKET;

castExpression: CAST SYM_LBRACKET expression AS dataType ( SYM_LBRACKET integerConstant SYM_RBRACKET)? SYM_RBRACKET;

functionExpression: IDENTIFIER SYM_LBRACKET ( expressionList )? SYM_RBRACKET;

bracketExpression: SYM_LBRACKET expression SYM_RBRACKET;

// arithmetic expressions
// https://help.sap.com/viewer/4fe29514fd584807ac9f2a04f6754767/2.0.03/en-US/20a380977519101494ceddd944e87527.html
operatorExpression:arithmeticOperatorExpression ;

arithmeticOperatorExpression:
    (SYM_PLUS | SYM_MINUS ) expression |            
    expression ( SYM_STAR | SYM_DIV ) expression |  
    expression ( SYM_PLUS | SYM_MINUS ) expression 
    ;

// [[DATABASE].SCHEMA].TABLE    
tableExpression: ( ( (QUOTED_IDENTIFIER|IDENTIFIER) SYM_DOT )? (QUOTED_IDENTIFIER|IDENTIFIER) SYM_DOT )? (QUOTED_IDENTIFIER|IDENTIFIER);
columnExpression: (tableExpression SYM_DOT)? (QUOTED_IDENTIFIER|IDENTIFIER);

    
dataType: TINYINT 
 | SMALLINT 
 | INTEGER 
 | BIGINT 
 | DECIMAL 
 | SMALLDECIMAL 
 | REAL 
 | DOUBLE 
 | ALPHANUM 
 | VARCHAR 
 | NVARCHAR 
 | DAYDATE 
 | DATE 
 | TIME 
 | SECONDDATE 
 | TIMESTAMP;

stringConstant: LIT_STRING | LIT_UNICODESTRING;
integerConstant: LIT_INT;


/*
 * <subquery> ::= <select_clause> <from_clause> [<where_clause>]
 [<group_by_clause>]
 [<having_clause>] 
 [<set_operator> <subquery> [{, <set_operator> <subquery>}...]]
 [<order_by_clause>] 
 [<limit>] 
 */
 
 selectStatement: selectStatementPart  (UNION (ALL)? selectStatementPart)* orderByClause?;
  
 selectStatementPart: selectClause fromClause whereClause? groupByClause? havingClause?;
 
 subQuery: SYM_LBRACKET selectStatement SYM_RBRACKET;
 
 // SELECT [TOP <unsigned_integer>] [ ALL | DISTINCT ] <select_list>
 selectClause: SELECT (TOP LIT_INT )? ( ALL | DISTINCT) ? selectList;
 
 selectList: selectItem ( SYM_COMMA selectItem)*;
 selectItem: (expression (AS (QUOTED_IDENTIFIER|IDENTIFIER))?) | 
 			 (((QUOTED_IDENTIFIER|IDENTIFIER) SYM_DOT)? SYM_STAR ) ;
 
 fromClause: FROM fromClausePart (SYM_COMMA fromClausePart)*;
 
 fromClausePart: fromTableElement (joinType? JOIN fromTableElement ON expression)* ;
 
 fromTableElement: (tableExpression   | subQuery) (AS (QUOTED_IDENTIFIER|IDENTIFIER) )?;
 joinType:   INNER | ( ( LEFT | RIGHT | FULL)   OUTER?   );	
 	
 
 whereClause: WHERE expression;
 groupByClause: GROUP BY expressionList;
 havingClause:HAVING expression;
 orderByClause: ORDER BY expressionList;
 limitClause: LIMIT LIT_INT;
 
 