/*
 * HuffmanTree.cpp
 *
 *  Created on: Mar 8, 2016
 *      Author: Administrator
 */
#include <stdio.h>
#include "HuffmanTree.h"

TreeNode * createEmptyTree(){
    TreeNode * root = createNYT_TreeNode();
    root->huffmanCode = "";

    return root;
}

TreeNode * search(TreeNode *root, TreeNode *node) {
    if (root != NULL) {
        if (root->group->number == node->group->number) {
            //cout << "Node " << node->group.group << " founded." << endl;
            return root;
        } else {
            TreeNode *left = search(root->l_child, node);
            if (left != NULL)
                return left;
            TreeNode *right = search(root->r_child, node);
            if (right != NULL)
                return right;
        }
    } else {
        //cout << "Node " << node->group.group << " not found" << endl;
        return NULL;

    }

}

TreeNode * search_nyt(TreeNode *root) {
    if (root != NULL) {
        if (root->flag == NYT_NODE) {
            //cout << "NYT node founded." << endl;
            return root;
        } else {
            TreeNode *left = search_nyt(root->l_child);
            if (left != NULL)
                return left;
            TreeNode *right = search_nyt(root->r_child);
            if (right != NULL)
                return right;
        }
    } else {
        //cout << "NYT node not found." << endl;
        return NULL;
    }

}

void buildCode(TreeNode *root) {
    int length = strlen(root->huffmanCode) + 1;
    char * code;

    if (root->l_child) {
        code = malloc(length);

        strcpy(code, root->huffmanCode);
        strcat(code, "0");

        root->l_child->huffmanCode = code;

        buildCode(root->l_child);
    }
    if (root->r_child) {
        code = malloc(length);

        strcpy(code, root->huffmanCode);
        strcat(code, "1");

        root->r_child->huffmanCode = code;

        buildCode(root->r_child);
    }
}

void printCode(TreeNode *root) {
    if (root->l_child == NULL && root->r_child == NULL)
        printf("%d %d %s", root->group->number, root->weight, root->huffmanCode);
    if (root->l_child != NULL)
        printCode(root->l_child);
    if (root->r_child != NULL)
        printCode(root->r_child);
}

char * traverse(TreeNode *root, float diff) {
    char *prefixCode;
    TreeNode *node;

    node = search(root, createNRM_TreeNode(diff));

    if (node == NULL) {
        //printf("node null\n");
        node = search_nyt(root);
    }

    prefixCode = malloc(strlen(node->huffmanCode));
    strcpy(prefixCode, node->huffmanCode);

    return prefixCode;
}

char * ConvertToBinary(int n, int length) {
  char * binaryString = malloc(1), *tmp;
  int size = 0, i, preSize;

  if (n == 0) {
    strcpy(binaryString, "0");
  } else {
    while (n != 0) {
      tmp = strdup(binaryString);
      binaryString = realloc(binaryString, ++size);

      strcpy(binaryString, (n % 2 == 0 ? "0" : "1"));
      strcat(binaryString, tmp);

      n /= 2;
      free(tmp);
    }
  }

  preSize = length - size;

  if (preSize > 0){
    tmp = binaryString;
    binaryString = malloc(length);

    for (i = 0; i < preSize; i++){
      strcat(binaryString, "0");
    }

    strcat(binaryString, tmp);
    free(tmp);
  }

  return binaryString;
}

char * suffixCode(float diff) {
    char * suffixCode;
    int index;
    Group *g = fromDiffToGroup(diff);
    int codeLength = getGroupBinaryLength(g);

    for (int i = 0; i < g->size; i++) {
        if (absFloat(diff) == g->difference[i]) {
            index = i;
            break;
            //cout << index << endl;
        }
    }
    if (diff < 0) {
        suffixCode = ConvertToBinary(g->size - index - 1, codeLength);
    }
    if (diff >= 0) {
        suffixCode = ConvertToBinary(g->size + index, codeLength);
    }

    return suffixCode;
}

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

char * ConvertToBCD(float diff) {
    int n = (int) (diff * 10);

    char *BCDcode = ConvertToBinary(n, BCD_CODE_LENGTH);

    if(diff < 0){
        BCDcode[0] = '1';
    }

    return BCDcode;
}

float BCDtoDecima(char * BCDcode){
    int n;
    float res;
    char first = BCDcode[0];

    if(first == '1'){
        BCDcode[0] = '0';
    }

    n = ConvertToDecima(BCDcode);
    res = (float)n/10;

    if(first == '1')
        return -res;
    else
        return res;
}

void addNode(TreeNode *root, float diff) {
    TreeNode* nyt = createNYT_TreeNode();
    TreeNode* nrm = createNRM_TreeNode(diff);
    TreeNode* temp = search_nyt(root);

    temp->l_child = nyt;
    temp->flag = COMP_NODE;
    temp->weight = -1;
    //temp->group.group = -2;
    temp->r_child = nrm;
    //cout << "New node " << temp->r_child->group.group << endl;

}

int reBalance_Step(TreeNode *root) {
    TreeNode *upper_node = NULL, *lower_node = NULL;
    int upper_weight, lower_weight;

    if(root->r_child){
        upper_node = root->r_child;
        upper_weight = upper_node->weight;
    }

    if(root->l_child && root->l_child->r_child){
        lower_node = root->l_child->r_child;
        lower_weight = lower_node->weight;
    }

    if(upper_node && lower_node){
        //printf("upper node & lower node\n");
        if(lower_weight > upper_weight){
            root->r_child = lower_node;
            root->l_child->r_child = upper_node;
            reBalance_Step(root->l_child);
            return 1;
        }
    }

    return 0;
}

void reBalance(TreeNode *root) {
    int count;
    count = reBalance_Step(root);
    while (count != 0) {
        count = reBalance_Step(root);
    }
    buildCode(root);
}

void printTree(TreeNode *root) {
    //if(tree->l_child == NULL && tree->r_child == NULL)
    // cout << tree->flag << " " << tree->group.group << " " << tree->weight
    //         << endl;
    printf("%d %d %d \n", root->flag, root->group->number, root->weight);
    if (root->l_child != NULL)
        printTree(root->l_child);
    if (root->r_child != NULL)
        printTree(root->r_child);

}

/*float * createDiffArr(float * currentData, float previousData) {
    float *diffArr;
    diffArr = (float *) malloc(currentData.size() * sizeof(float *));
    for (int i = 0; i < currentData.size(); i++) {
        if (i == 0) {
            diffArr[i] = currentData[i] - previousData;
            diffArr[i] = (float) round(diffArr[i] * 10) / 10;
        } else {
            diffArr[i] = currentData[i] - currentData[i - 1];
            diffArr[i] = (float) round(diffArr[i] * 10) / 10;
        }
    }
    return diffArr;
}*/

char * encoder(float *data, int length, TreeNode *root) {
    char *preCode, *sufCode, *code = malloc(0), *tmp;
    TreeNode *temp;

    for (int i = 0; i < length; i++) {
        temp = createNRM_TreeNode(data[i]);
        temp = search(root, temp);
        if (temp == NULL) {
            preCode = traverse(root, data[i]);
            sufCode = ConvertToBCD(data[i]);

            addNode(root, data[i]);
            reBalance(root);
        } else {
            preCode = traverse(root, data[i]);
            sufCode = suffixCode(data[i]);

            temp->weight += 1;
            reBalance(root);
        }

        code = realloc(code, strlen(code) + strlen(preCode) + strlen(sufCode) + 1);

        strcat(code, preCode);
        strcat(code, sufCode);

        free(preCode);
        free(sufCode);
    }


    return code;
}

float getDataFromBCDCode(char *code){
    char *suffixCode;
    float data;
    int decima;

    suffixCode = malloc(BCD_CODE_LENGTH + 1);
    memcpy(suffixCode, code, BCD_CODE_LENGTH);
    suffixCode[BCD_CODE_LENGTH] = '\0';

    decima = ConvertToDecima(suffixCode);
    data = (float) decima / 10;
    free(suffixCode);

    return data;
}

float getDataFromCode(Group * group, char *code, int length){
    char * suffixCode;
    int index;
    float data;

    suffixCode = malloc(length + 1);
    memcpy(suffixCode, code, length);
    suffixCode[length] = '\0';

    index = ConvertToDecima(suffixCode);

    if(index >= group->size){
        index -= group->size;
    }

    data = group->difference[index];

    return data;
}

float * decoder(char * code, TreeNode *root) {
    TreeNode *currentNode;
    char *suffixCode;
    float *dataArray = malloc(sizeof(float)), data;

    int count = 0, codeLength = strlen(code), prefixCount = 0, data_count = 0;
    int i, sufCodeLength = 0;

    char currentCode = code[count];

    while (count < codeLength){
        currentCode = code[count];
        currentNode = root;

        dataArray = realloc(dataArray, (data_count + 1) * sizeof(float));
        if(currentNode->flag == NYT_NODE){
            data = getDataFromBCDCode(&code[count]);
            dataArray[data_count++] = data;
            addNode(root, data);
            reBalance(root);
            count += BCD_CODE_LENGTH;
        } else if (currentNode->flag == COMP_NODE){
            // Duyet tung ki tu 0
            while(currentCode == '0' && currentNode->flag != NYT_NODE){
                currentNode = currentNode->l_child;
                count++;
                currentCode = code[count];
            }

            if(currentNode->flag == NYT_NODE){
                data = getDataFromBCDCode(&code[count]);
                dataArray[data_count++] = data;
                addNode(root, data);
                reBalance(root);
                count += BCD_CODE_LENGTH;
            } else if(currentNode->flag == COMP_NODE){
                // Doc ki tu 1
                count++;
                currentNode = currentNode->r_child;

                sufCodeLength = getGroupBinaryLength(currentNode->group);
                data = getDataFromCode(currentNode->group, &code[count], sufCodeLength);
                dataArray[data_count++] = data;

                count += sufCodeLength;
                currentNode->weight++;
                reBalance(root);
            }
        }

    printf("group %d\n", root->r_child->group->number);
    }



    return dataArray;
}

int main(){
    TreeNode * root = createEmptyTree();
    TreeNode *root2 = createEmptyTree();

    float *f;
    float data[5] = {0.1, 0.2, 0.2, 0.2, 0.1};

    char *s = encoder(data, 5, root);
    f = decoder(s, root2);

    printf("%s\n", s);

    int i;
    for (i = 0; i < 5; i++){
        printf("%f ", f[i]);
    }
    printf("\n");
}
