#include <stdio.h>
#include <string.h>
char expString [100];
char *p;

int expression();

int constant(){
    int x=0;
    while(*p>='0' && *p<='9')
        x = x*10 + *p++ - '0';
    return (x);
}

int term(){
    int x;
    if(*p == '('){
        p++;
        x=expression();
        p++;
        return x;
    }
    else
        return constant();
}

int expression(){
    int x;
    x=term();
    while(*p == '+' || *p == '-' || *p == '*'){
        if(*p == '+'){
            p++;
            x=x+term();
        }
        else if(*p == '-'){
            p++;
            x=x-term();
        }
        else if(*p == '*'){
            p++;
            x=x*term();
        }
    }
   return x; 
}

int main(){
    p = &expString[0];
    printf("Enter Expression- ");
    scanf("%s",p);
    printf("Result= %i\n",expression());
    return 0;
}