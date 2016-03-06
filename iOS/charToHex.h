#include "stdio.h"

char hexDigit(unsigned n)
{
    if (n < 10) {
        return n + '0';
    } else {
        return (n - 10) + 'A';
    }
}
void charToHex(char c, char hex[3])
{
    hex[0] = hexDigit(c / 0x10);
    hex[1] = hexDigit(c % 0x10);
    hex[2] = '\0';
}
/*int main (void)
{
  char hex[3] = {0,0,0};
  charToHex('A', hex);
  printf("A is %s in hex\n", hex);

  charToHex('a', hex);
  printf("a is %s in hex\n", hex);
}
*/
