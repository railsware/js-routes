import {
  inbox_message_attachment_path,
  inboxes_path,
  serialize,
  configure,
  ModuleType,
} from "./routes.spec";

inboxes_path();
// extensive query options
inboxes_path({
  locale: "en",
  search: {
    q: "ukraine",
    page: 3,
    keywords: ["large", "small", { advanced: true }],
  },
});

inbox_message_attachment_path(1, "2", true);
inbox_message_attachment_path(1, "2", true, { format: "json" });

// serialize test
serialize({
  locale: "en",
  search: {
    q: "ukraine",
    page: 3,
    keywords: ["large", "small", { advanced: true }],
  },
});

// configure test
configure({
  default_url_options: { port: 1, host: null },
  prefix: "",
  serializer: (value) => JSON.stringify(value),
});
