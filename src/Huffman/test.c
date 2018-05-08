#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

int ConvertToDecima(char * binaryCode){
    int i, codeLength = strlen(binaryCode);
    char codeChar;
    int codeNumber, decima = 0;

    for (i = 0; i < codeLength; i++){
        codeChar = binaryCode[codeLength - i - 1];
        codeNumber = codeChar - '0';

        if(codeNumber){
            decima += 1 << i;
        }
    }

    return decima;
}

int main(){
  char *s = malloc(10);
  char *s2 = malloc(120);

  printf("%ld\n", strlen(s2));

  strcpy(s, "1234");
  strcpy(s2, "5678");

  printf("%ld\n", strlen(s2));

  strcat(s, s2);
  free(s2);

  //printf("%s\n", s);
  printf("%ld\n", strlen(s2));
}
