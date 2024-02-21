package com.levio.awsdemo.emailrequestprocessor.client;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

public class SaasClient {
    public String getInference(String message) throws IOException {
        String queryParams = "?query=" + URLEncoder.encode(message, StandardCharsets.UTF_8) + "&collectionName=levio-hr";
        String apiUrl = System.getenv("API_URL");

        URL url = new URL(apiUrl + queryParams);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setRequestProperty("x-api-key", System.getenv("API_KEY"));

        StringBuilder response = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
        }

        if (conn.getResponseCode() == HttpURLConnection.HTTP_OK) {
            JSONObject jsonObj = new JSONObject(response.toString());

            return jsonObj.getString("completion");
        }
        return null;
    }
}
