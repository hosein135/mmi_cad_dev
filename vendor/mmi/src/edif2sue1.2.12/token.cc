// ************************************************************************
// 
// Copyright (c) 1995-2002 Juniper Networks, Inc. All rights reserved.
// 
// Permission is hereby granted, without written agreement and without
// license or royalty fees, to use, copy, modify, and distribute this
// software and its documentation for any purpose, provided that the
// above copyright notice and the following three paragraphs appear in
// all copies of this software.
// 
// IN NO EVENT SHALL JUNIPER NETWORKS, INC. BE LIABLE TO ANY PARTY FOR
// DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
// ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
// JUNIPER NETWORKS, INC. HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// JUNIPER NETWORKS, INC. SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
// NON-INFRINGEMENT.
// 
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND JUNIPER
// NETWORKS, INC. HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
// UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
// 
// ************************************************************************

#include <util.h>


char *keyword_names[] = {
	"INVALID",
	"ENDOFFILE",
	"LPAR",
	"RPAR",
	"STRING",
	"INTEGER",

	"KW_ARC",
	"KW_ANNOTATE",
	"KW_ARRAY",
	"KW_BOUNDINGBOX",
	"KW_CELL",
	"KW_COMMENTGRAPHICS",
	"KW_CONNECTLOCATION",
	"KW_CONTENTS",
	"KW_DIRECTION",
	"KW_DISPLAY",
	"KW_DOT",
	"KW_EDIF",
	"KW_FIGURE",
	"KW_FIGUREGROUP",
	"KW_FIGUREGROUPOVERRIDE",
	"KW_INSTANCE",
	"KW_JUSTIFY",
	"KW_KEYWORDDISPLAY",
	"KW_LIBRARY",
	"KW_NAME",
	"KW_NET",
	"KW_ORIENTATION",
	"KW_ORIGIN",
	"KW_PAGE",
	"KW_PORT",
	"KW_PROPERTY",
	"KW_PORTIMPLEMENTATION",
	"KW_STRING",
	"KW_STRINGDISPLAY",
	"KW_TEXTHEIGHT",
	"KW_TRANSFORM",
	"KW_VIEW",
	"KW_VIEWTYPE",
	"KW_RENAME",

	"KW_CELLTYPE",
	"KW_COMMENT",
	"KW_DESIGN",
	"KW_EDIFLEVEL",
	"KW_EDIFVERSION",
	"KW_EXTERNAL",
	"KW_KEYWORDMAP",
	"KW_STATUS",
	"KW_TECHNOLOGY",
	"KW_USERDATA"
};


TOKEN::TOKEN(TOKEN_TYPE arg_type, char *arg_string)
   : type(arg_type), integer(0)
{
	string = strdup(arg_string);
}	

TOKEN::TOKEN(char *arg_string)
    : type(STRING), integer(0)
{
	string = strdup(arg_string);
}

TOKEN::TOKEN(int arg_integer)
    : type(INTEGER), string(NULL), integer(arg_integer)
{
}

TOKEN::~TOKEN()
{
	if (string) delete string;
}

TOKEN_TYPE
TOKEN::get_type()
{
	return type;
}

char *
TOKEN::get_string()
{
	BOOLEAN asciiescape = false;
	char *return_string = strdup(string);

	// ascii escape un-substitution....
	char *p = string;
	char *r = return_string;
	while (*p != '\0') {
		if (*p == '%') {
			int code = 0;	// ascii code accumulator
			char c = '\0';	// equivalent character
 			char *q = p;
			while (1) {
				q++;
				int digit;
				switch (*q) {
				    case '0':	digit = 0; break;
				    case '1':	digit = 1; break;
				    case '2':	digit = 2; break;
				    case '3':	digit = 3; break;
				    case '4':	digit = 4; break;
				    case '5':	digit = 5; break;
				    case '6':	digit = 6; break;
				    case '7':	digit = 7; break;
				    case '8':	digit = 8; break;
				    case '9':	digit = 9; break;
				    case '%':		   break;
				    default:	q = NULL;  break;
				}
				if (q == NULL) break;
				if (*q != '%') {
					code = code * 10 + digit;
					continue;
				}

				switch (code) {
				    case 10:	c = 'L';	break;	// .. line feed
				    case 32:	c = ' ';	break;
				    case 33:	c = '!';	break;
				    case 34:	c = '"';	break;
				    case 35:	c = '#';	break;
				    case 36:	c = '$';	break;
				    case 37:	c = '%';	break;
				    case 38:	c = '&';	break;
				    case 39:	c = '\'';	break;
				    case 40:	c = '(';	break;
				    case 41:	c = ')';	break;
				    case 42:	c = '*';	break;
				    case 43:	c = '+';	break;
				    case 44:	c = ',';	break;
				    case 45:	c = '-';	break;
				    case 46:	c = '.';	break;
				    case 47:	c = '/';	break;
				    case 48:	c = '0';	break;
				    case 49:	c = '1';	break;
				    case 50:	c = '2';	break;
				    case 51:	c = '3';	break;
				    case 52:	c = '4';	break;
				    case 53:	c = '5';	break;
				    case 54:	c = '6';	break;
				    case 55:	c = '7';	break;
				    case 56:	c = '8';	break;
				    case 57:	c = '9';	break;
				    case 58:	c = ':';	break;
				    case 59:	c = ';';	break;
				    case 60:	c = '<';	break;
				    case 61:	c = '=';	break;
				    case 62:	c = '>';	break;
				    case 63:	c = '?';	break;
				    case 64:	c = '@';	break;
				    case 65:	c = 'A';	break;
				    case 66:	c = 'B';	break;
				    case 67:	c = 'C';	break;
				    case 68:	c = 'D';	break;
				    case 69:	c = 'E';	break;
				    case 70:	c = 'F';	break;
				    case 71:	c = 'G';	break;
				    case 72:	c = 'H';	break;
				    case 73:	c = 'I';	break;
				    case 74:	c = 'J';	break;
				    case 75:	c = 'K';	break;
				    case 76:	c = 'L';	break;
				    case 77:	c = 'M';	break;
				    case 78:	c = 'N';	break;
				    case 79:	c = 'O';	break;
				    case 80:	c = 'P';	break;
				    case 81:	c = 'Q';	break;
				    case 82:	c = 'R';	break;
				    case 83:	c = 'S';	break;
				    case 84:	c = 'T';	break;
				    case 85:	c = 'U';	break;
				    case 86:	c = 'V';	break;
				    case 87:	c = 'W';	break;
				    case 88:	c = 'X';	break;
				    case 89:	c = 'Y';	break;
				    case 90:	c = 'Z';	break;
				    case 91:	c = '[';	break;
				    case 92:	c = '\\';	break;
				    case 93:	c = ']';	break;
				    case 94:	c = '^';	break;
				    case 95:	c = '_';	break;
				    case 96:	c = '`';	break;
				    case 97:	c = 'a';	break;
				    case 98:	c = 'b';	break;
				    case 99:	c = 'c';	break;
				    case 100:	c = 'd';	break;
				    case 101:	c = 'e';	break;
				    case 102:	c = 'f';	break;
				    case 103:	c = 'g';	break;
				    case 104:	c = 'h';	break;
				    case 105:	c = 'i';	break;
				    case 106:	c = 'j';	break;
				    case 107:	c = 'k';	break;
				    case 108:	c = 'l';	break;
				    case 109:	c = 'm';	break;
				    case 110:	c = 'n';	break;
				    case 111:	c = 'o';	break;
				    case 112:	c = 'p';	break;
				    case 113:	c = 'q';	break;
				    case 114:	c = 'r';	break;
				    case 115:	c = 's';	break;
				    case 116:	c = 't';	break;
				    case 117:	c = 'u';	break;
				    case 118:	c = 'v';	break;
				    case 119:	c = 'w';	break;
				    case 120:	c = 'x';	break;
				    case 121:	c = 'y';	break;
				    case 122:	c = 'z';	break;
				    case 123:	c = '{';	break;
				    case 124:	c = '|';	break;
				    case 125:	c = '}';	break;
				    case 126:	c = '~';	break;
				    default:
					printf("unprintable character 0x%x in escape sequence\n", code);
					c = 'X';
				}
				break;
			}
			if (c == '\0') {
				// not valid conversion string, write it across
				*r++ = *p++;
			} else {
				// insert the converted value, bump p past final '%'
				*r++ = c;
				p = ++q;
				asciiescape = true;
			}
		} else {		
			// vanilla character
			*r++ = *p++;
		}
	}
	*r = '\0';

	if (asciiescape == true)	printf("from escaped: \"%s\"\n", return_string);
	return return_string;
}

int
TOKEN::get_integer()
{
	if (type != INTEGER) {
		printf("get_integer of non-integer token\n");
		exit(-1);
	}
	else			return integer;
}
