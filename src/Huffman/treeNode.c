#include "treeNode.h"

TreeNode * createNYT_TreeNode(){
    TreeNode * node;

    node = (TreeNode*)malloc(sizeof(TreeNode));
    node->group = (Group*)malloc(sizeof(Group));
    node->huffmanCode = malloc(1);

    node->flag = NYT_NODE;
    node->weight = 0;
    node->l_child = NULL;
    node->r_child = NULL;
    node->group->number = -1;

    return node;
}

TreeNode * createNRM_TreeNode(float diff){
    TreeNode * node;

    node = malloc(sizeof(TreeNode));
    node->huffmanCode = malloc(1);

    node->flag = NRM_NODE;
    node->weight = 1;
    node->l_child = 0;
    node->r_child = 0;
    //node->group.fromDiffToGroup(diff);
    node->group = fromDiffToGroup(diff);

    return node;
}

/*void main(){
    TreeNode *node;
    node = createNRM_TreeNode(tree, 1.5);
    printf("%d\n", node->group->number);
}*/
