package com.levio.awsdemo.formrequestprocessor.service;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.Table;

public class DynamoDbService {
    AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().build();
    DynamoDB dynamoDB = new DynamoDB(client);

    public Item getItem(String tableName, String primaryKeyName, String primaryKeyValue) {
        Table table = dynamoDB.getTable(tableName);

        return table.getItem(primaryKeyName, primaryKeyValue);
    }
}
