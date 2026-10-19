import React from 'react';

type Props = { name: string };

export function App({ name }: Props) {
  const items: Array<string> = ['a', 'b'];
  return (
    <div className="app">
      <h1>Hello {name}</h1>
      <ul>
        {items.map((i) => (
          <li key={i}>{i}</li>
        ))}
      </ul>
    </div>
  );
}
