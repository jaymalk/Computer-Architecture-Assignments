#include <stdio.h>

int main() {
  char s[] = "";
  int pos = 0;
  int ans=0, num=0, op=0, temp = 0;
  char arg;
  start:
    arg = s[pos];
    if(arg >= '0')
      goto number;
    else
      goto operation;
  number:
    temp = num*10;
    num = temp;
    num = num + (int)arg - 48;
    pos++;
    goto start;
  operation:
    if(op == 0)
      ans = ans + num;
    else if(op == 1)
      ans = ans - num;
    else
      ans = ans*num;
    if(arg == '\0')
      goto exit;
    num = 0;
    if(arg == '+')
      op = 0;
    else if(arg == '-')
      op = 1;
    else
      op = -1;
    pos++;
    goto start;
  exit:
    printf("%d\n", ans);
    return 0;
}
