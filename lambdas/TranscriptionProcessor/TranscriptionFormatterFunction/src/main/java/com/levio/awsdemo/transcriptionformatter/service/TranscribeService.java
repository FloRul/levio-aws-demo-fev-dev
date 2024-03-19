package com.levio.awsdemo.transcriptionformatter.service;

import org.json.JSONArray;
import org.json.JSONObject;

import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;

public class TranscribeService {

    public String format(String transcription) {
        JSONObject data = new JSONObject(transcription);
        JSONArray labels = data.getJSONObject("results").getJSONObject("speaker_labels").getJSONArray("segments");
        HashMap<String, String> speakerStartTimes = new HashMap<>();
        for (int i = 0; i < labels.length(); i++) {
            JSONObject label = labels.getJSONObject(i);
            JSONArray items = label.getJSONArray("items");
            for (int j = 0; j < items.length(); j++) {
                JSONObject item = items.getJSONObject(j);
                speakerStartTimes.put(item.getString("start_time"), item.getString("speaker_label"));
            }
        }
        JSONArray items = data.getJSONObject("results").getJSONArray("items");
        ArrayList<HashMap<String, String>> lines = new ArrayList<>();
        StringBuilder line = new StringBuilder();
        String time = "0";
        String speaker = "null";
        for (int i = 0; i < items.length(); i++) {
            JSONObject item = items.getJSONObject(i);
            String content = item.getJSONArray("alternatives").getJSONObject(0).getString("content");
            if (item.has("start_time")) {
                String currentSpeaker = speakerStartTimes.get(item.getString("start_time"));
                if (!currentSpeaker.equals(speaker)) {
                    if (!speaker.equals("null")) {
                        HashMap<String, String> lineData = new HashMap<>();
                        lineData.put("speaker", speaker);
                        lineData.put("line", line.toString());
                        lineData.put("time", time);
                        lines.add(lineData);
                    }
                    line = new StringBuilder(content);
                    speaker = currentSpeaker;
                    time = item.getString("start_time");
                } else {
                    line.append(" ").append(content);
                }
            } else if (item.getString("type").equals("punctuation")) {
                line.append(content);
            }
        }
        HashMap<String, String> lineData = new HashMap<>();
        lineData.put("speaker", speaker);
        lineData.put("line", line.toString());
        lineData.put("time", time);
        lines.add(lineData);

        lines.sort((a, b) -> Float.compare(Float.parseFloat(a.get("time")), Float.parseFloat(b.get("time"))));

        StringBuilder transcriptionFormatted = new StringBuilder();
        for (HashMap<String, String> lineInfo : lines) {
            long timeInSeconds = Math.round(Double.parseDouble(lineInfo.get("time")));
            String outputLine = "[" + Duration.ofSeconds(timeInSeconds).toString().substring(2).toLowerCase() + "] " + lineInfo.get("speaker") + ": " + lineInfo.get("line") + "\n\n";
            transcriptionFormatted.append(outputLine);
        }

        return transcriptionFormatted.toString();
    }
}
