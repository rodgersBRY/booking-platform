"use client";

import { useEffect, useState } from "react";

export function HeaderClock() {
  const [time, setTime] = useState("");

  useEffect(() => {
    function tick() {
      setTime(
        new Date().toLocaleTimeString("en-KE", {
          hour: "2-digit",
          minute: "2-digit",
        }),
      );
    }

    tick();
    const id = setInterval(tick, 10_000);
    return () => clearInterval(id);
  }, []);

  if (!time) return null;

  return (
    <span className="hidden sm:block text-xl font-mono tabular-nums opacity-90">
      {time}
    </span>
  );
}
