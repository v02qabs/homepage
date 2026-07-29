import google.generativeai as genai

genai.configure(api_key="AQ.Ab8RN6JvjvDtPtx6HtzKtRaDbFiWwUWc4ExiCDZqUImaJTqRTw")

for m in genai.list_models():
  if "generateContent" in m.supported_generation_methods:
    print(m.name)
