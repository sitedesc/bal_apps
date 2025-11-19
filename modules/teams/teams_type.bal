public type TMIncomingWebhookText record {
    string text;
};

public type TMIncomingWebhookFact record {
    string name;
    string value;
};

public type TMIncomingWebhookFacts record {
    string title;
    TMIncomingWebhookFact[] facts;
    boolean markdown = false;
};

public type TMIncomingWebhookSection TMIncomingWebhookText|TMIncomingWebhookFacts;

public type TMMessageCard record {
    "MessageCard"? \@type = "MessageCard";
    "http://schema.org/extensions"? \@context = "http://schema.org/extensions";
    string summary;
    string title;
    TMIncomingWebhookSection[] sections;
};

public type AWMessageCard record {
    string title;
    string description;
    string channel_id;
    string|map<string>[] list;
};

public type MessageCard TMMessageCard|AWMessageCard;
