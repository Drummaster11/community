
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TIMEZONE = "America/New_York"

def clock_screen():
    now = time.now().in_location(TIMEZONE)

    return render.Root(
        delay = 500,
        max_age = 60,
        child = render.Text(
            content = now.format("3:04 PM"),
            font = "6x13",
            color = "#FFFFFF",
        ),
    )

def message_screen(message):
    return render.Root(
        max_age = 30,
        child = render.Text(
            content = message,
            font = "CG-pixel-4x5-mono",
            color = "#FFAA00",
        ),
    )

def dispatch_screen(dispatch):
    category = dispatch.get("category") or "DISPATCH"
    color = dispatch.get("color") or "#FFFFFF"
    town = dispatch.get("town") or ""
    house = dispatch.get("houseNumber") or ""
    street = dispatch.get("street") or ""
    description = dispatch.get("description") or ""

    address = (house + " " + street).strip()

    children = [
        render.Text(
            content = category,
            font = "CG-pixel-4x5-mono",
            color = color,
        ),
    ]

    if town:
        children.append(
            render.Text(
                content = town,
                font = "CG-pixel-3x5-mono",
                color = "#FFFFFF",
            ),
        )

    if address:
        children.append(
            render.WrappedText(
                content = address,
                font = "CG-pixel-3x5-mono",
                color = "#FFFFFF",
                width = 64,
                align = "center",
            ),
        )

    if description:
        children.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = description,
                    font = "CG-pixel-3x5-mono",
                    color = "#FFFFFF",
                ),
            ),
        )

    return render.Root(
        delay = 500,
        max_age = 30,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = children,
        ),
    )

def main(config):
    feed_url = config.str("feed_url")
    feed_token = config.str("feed_token")

    if not feed_url or not feed_token:
        return clock_screen()

    response = http.post(
        feed_url,
        form_body = {
            "token": feed_token,
            "action": "getActiveDispatch",
        },
    )

    if response.status_code != 200:
        return message_screen("FEED ERROR")

    data = response.json()

    if not data.get("ok"):
        return message_screen("AUTH ERROR")

    if not data.get("active"):
        return clock_screen()

    return dispatch_screen(data.get("dispatch") or {})

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed_url",
                name = "Private Feed URL",
                desc = "Your Google Apps Script web app URL",
                icon = "link",
            ),
            schema.Text(
                id = "feed_token",
                name = "Feed Access Token",
                desc = "Your private feed token. This field is not masked.",
                icon = "key",
            ),
        ],
    )
