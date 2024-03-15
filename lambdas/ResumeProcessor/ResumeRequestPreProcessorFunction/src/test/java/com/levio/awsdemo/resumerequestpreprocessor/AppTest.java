package com.levio.awsdemo.resumerequestpreprocessor;

import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import org.junit.Test;

public class AppTest {
  @Test
  public void successfulResponse() {
      String key = "resume/transcription/f9n7mfg2q03r35r05ro3ih8pa2og75nndj8k6v81.json";
      int lastDotIndex = key.lastIndexOf('.');
      int lastSlashIndex = key.lastIndexOf('/', lastDotIndex - 1);
      String result = key.substring(lastSlashIndex + 1, lastDotIndex);

      System.out.println(result);
  }
}
